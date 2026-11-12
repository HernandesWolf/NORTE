package br.com.norte.ia;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class LimitadorDeUsoIaTest {

    /** Relógio que anda sob controle do teste, para simular a passagem do tempo sem esperar. */
    private static final class RelogioMutavel extends Clock {
        private Instant agora = Instant.parse("2026-11-10T12:00:00Z");

        void avancar(Duration d) {
            agora = agora.plus(d);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return agora;
        }
    }

    private RelogioMutavel relogio;

    @BeforeEach
    void preparar() {
        relogio = new RelogioMutavel();
    }

    /** Teto global folgado (1000), para os testes por pessoa não esbarrarem nele. */
    private LimitadorDeUsoIa limitador(int porMinuto, int porDia) {
        return limitador(porMinuto, porDia, 1000);
    }

    private LimitadorDeUsoIa limitador(int porMinuto, int porDia, int globalPorDia) {
        return new LimitadorDeUsoIa(relogio, new IaProperties("desligado", "", "", porMinuto, porDia, globalPorDia));
    }

    @Test
    void permiteAteOLimitePorMinuto_eRecusaAMensagemSeguinteComRetryAfter() {
        LimitadorDeUsoIa limitador = limitador(3, 100);
        UUID pessoa = UUID.randomUUID();

        for (int i = 0; i < 3; i++) {
            limitador.registrar(pessoa);
        }
        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(pessoa));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertEquals(60L, e.getRetryAfterSegundos());
    }

    @Test
    void depoisDeUmMinuto_aPessoaPodeMandarDeNovo() {
        LimitadorDeUsoIa limitador = limitador(1, 100);
        UUID pessoa = UUID.randomUUID();
        limitador.registrar(pessoa);
        assertThrows(ApiException.class, () -> limitador.registrar(pessoa));

        relogio.avancar(Duration.ofSeconds(61));

        assertDoesNotThrow(() -> limitador.registrar(pessoa));
    }

    @Test
    void limiteDiario_recusaComAvisoDeHojeERetryAfterDeUmDia() {
        LimitadorDeUsoIa limitador = limitador(100, 3);
        UUID pessoa = UUID.randomUUID();
        for (int i = 0; i < 3; i++) {
            limitador.registrar(pessoa);
        }

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(pessoa));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertTrue(e.getMessage().contains("hoje"));
        assertEquals(Duration.ofHours(24).toSeconds(), e.getRetryAfterSegundos());
    }

    @Test
    void depoisDe24Horas_oLimiteDiarioVoltaAoZero() {
        LimitadorDeUsoIa limitador = limitador(100, 1);
        UUID pessoa = UUID.randomUUID();
        limitador.registrar(pessoa);
        assertThrows(ApiException.class, () -> limitador.registrar(pessoa));

        relogio.avancar(Duration.ofHours(24));

        assertDoesNotThrow(() -> limitador.registrar(pessoa));
    }

    @Test
    void cadaPessoaTemOSeuProprioContador() {
        LimitadorDeUsoIa limitador = limitador(1, 100);
        UUID ana = UUID.randomUUID();
        UUID bia = UUID.randomUUID();
        limitador.registrar(ana);

        assertThrows(ApiException.class, () -> limitador.registrar(ana));
        assertDoesNotThrow(() -> limitador.registrar(bia));
    }

    @Test
    void tentativaRecusadaNaoGastaAcotaDoDia() {
        // 1 por minuto e 3 por dia: se as recusas contassem, a 4ª tentativa já bateria no limite diário.
        LimitadorDeUsoIa limitador = limitador(1, 3);
        UUID pessoa = UUID.randomUUID();

        limitador.registrar(pessoa); // dia: 1
        assertThrows(ApiException.class, () -> limitador.registrar(pessoa)); // recusada pelo minuto
        relogio.avancar(Duration.ofSeconds(61));
        limitador.registrar(pessoa); // dia: 2
        relogio.avancar(Duration.ofSeconds(61));
        assertDoesNotThrow(() -> limitador.registrar(pessoa)); // dia: 3 (só passa se a recusa não contou)
        relogio.avancar(Duration.ofSeconds(61));

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(pessoa));
        assertTrue(e.getMessage().contains("hoje"));
    }

    @Test
    void tetoGlobal_recusaQuandoPessoasDiferentesJuntasEsgotamACota() {
        LimitadorDeUsoIa limitador = limitador(100, 100, 3);
        for (int i = 0; i < 3; i++) {
            limitador.registrar(UUID.randomUUID()); // três pessoas diferentes, uma mensagem cada
        }

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(UUID.randomUUID()));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertTrue(e.getMessage().contains("hoje"));
        assertEquals(Duration.ofHours(24).toSeconds(), e.getRetryAfterSegundos());
    }

    @Test
    void tetoGlobal_voltaAoZeroDepoisDe24Horas() {
        LimitadorDeUsoIa limitador = limitador(100, 100, 1);
        limitador.registrar(UUID.randomUUID());
        assertThrows(ApiException.class, () -> limitador.registrar(UUID.randomUUID()));

        relogio.avancar(Duration.ofHours(24));

        assertDoesNotThrow(() -> limitador.registrar(UUID.randomUUID()));
    }

    @Test
    void recusaPeloTetoGlobalNaoGastaACotaPessoal() {
        LimitadorDeUsoIa limitador = limitador(100, 1, 1);
        UUID ana = UUID.randomUUID();
        UUID bia = UUID.randomUUID();
        limitador.registrar(ana); // global: 1 de 1, a partir de T0
        relogio.avancar(Duration.ofHours(12));
        assertThrows(ApiException.class, () -> limitador.registrar(bia)); // recusada pelo teto global

        relogio.avancar(Duration.ofHours(12)); // T0 + 24h: o global zerou, a janela pessoal da Bia ainda vale

        // Só passa se a recusa anterior não gastou a única mensagem diária da Bia.
        assertDoesNotThrow(() -> limitador.registrar(bia));
    }

    @Test
    void recusaPessoalNaoGastaOTetoGlobal() {
        LimitadorDeUsoIa limitador = limitador(1, 100, 2);
        UUID ana = UUID.randomUUID();
        UUID bia = UUID.randomUUID();
        UUID cris = UUID.randomUUID();
        limitador.registrar(ana); // global: 1 de 2
        assertThrows(ApiException.class, () -> limitador.registrar(ana)); // recusada pelo minuto: não conta no global

        assertDoesNotThrow(() -> limitador.registrar(bia)); // global: 2 de 2 (só passa se a recusa da Ana não contou)

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(cris));
        assertTrue(e.getMessage().contains("procura"));
    }
}
