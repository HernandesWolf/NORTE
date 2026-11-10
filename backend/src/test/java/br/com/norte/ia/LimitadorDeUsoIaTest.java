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

    private LimitadorDeUsoIa limitador(int porMinuto, int porDia) {
        return new LimitadorDeUsoIa(relogio, new IaProperties("desligado", "", "", porMinuto, porDia));
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
}
