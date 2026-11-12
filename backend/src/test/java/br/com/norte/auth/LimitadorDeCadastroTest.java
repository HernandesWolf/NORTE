package br.com.norte.auth;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class LimitadorDeCadastroTest {

    /** Relógio que anda sob controle do teste, para simular a passagem do tempo sem esperar. */
    private static final class RelogioMutavel extends Clock {
        private Instant agora = Instant.parse("2026-11-12T12:00:00Z");

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

    private static final String IP = "203.0.113.7";

    private RelogioMutavel relogio;

    @BeforeEach
    void preparar() {
        relogio = new RelogioMutavel();
    }

    private LimitadorDeCadastro limitador(int maximo) {
        return new LimitadorDeCadastro(relogio, maximo);
    }

    @Test
    void permiteAteOLimite_eRecusaOCadastroSeguinteComRetryAfter() {
        LimitadorDeCadastro limitador = limitador(3);
        for (int i = 0; i < 3; i++) {
            limitador.registrar(IP);
        }

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(IP));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertEquals(Duration.ofHours(1).toSeconds(), e.getRetryAfterSegundos());
    }

    @Test
    void retryAfterDiminuiConformeAJanelaAnda() {
        LimitadorDeCadastro limitador = limitador(1);
        limitador.registrar(IP);
        relogio.avancar(Duration.ofMinutes(20));

        ApiException e = assertThrows(ApiException.class, () -> limitador.registrar(IP));

        assertEquals(Duration.ofMinutes(40).toSeconds(), e.getRetryAfterSegundos());
    }

    @Test
    void depoisDeUmaHora_oIpPodeSeCadastrarDeNovo() {
        LimitadorDeCadastro limitador = limitador(1);
        limitador.registrar(IP);
        assertThrows(ApiException.class, () -> limitador.registrar(IP));

        relogio.avancar(Duration.ofHours(1));

        assertDoesNotThrow(() -> limitador.registrar(IP));
    }

    @Test
    void cadaIpTemOSeuProprioContador() {
        LimitadorDeCadastro limitador = limitador(1);
        limitador.registrar("203.0.113.1");

        assertThrows(ApiException.class, () -> limitador.registrar("203.0.113.1"));
        assertDoesNotThrow(() -> limitador.registrar("203.0.113.2"));
    }

    @Test
    void tentativaRecusadaNaoEstendeABloqueio() {
        LimitadorDeCadastro limitador = limitador(1);
        limitador.registrar(IP);
        relogio.avancar(Duration.ofMinutes(30));
        assertThrows(ApiException.class, () -> limitador.registrar(IP)); // recusada: não reinicia a janela

        relogio.avancar(Duration.ofMinutes(30)); // 1h desde o primeiro cadastro

        assertDoesNotThrow(() -> limitador.registrar(IP));
    }

    @Test
    void limiteInvalidoCaiNoPadraoDeCinco() {
        LimitadorDeCadastro limitador = limitador(0);
        for (int i = 0; i < 5; i++) {
            limitador.registrar(IP);
        }

        assertThrows(ApiException.class, () -> limitador.registrar(IP));
    }
}
