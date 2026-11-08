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

class LimitadorDeLoginTest {

    /** Relógio que anda sob controle do teste, para simular a passagem de minutos sem esperar. */
    private static final class RelogioMutavel extends Clock {
        private Instant agora = Instant.parse("2026-11-07T12:00:00Z");

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
    private LimitadorDeLogin limitador;

    @BeforeEach
    void preparar() {
        relogio = new RelogioMutavel();
        limitador = new LimitadorDeLogin(relogio);
    }

    private void falhar(String chave, int vezes) {
        for (int i = 0; i < vezes; i++) {
            limitador.registrarFalha(chave);
        }
    }

    @Test
    void abaixoDoLimite_naoBloqueia() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS - 1);

        assertDoesNotThrow(() -> limitador.verificar("a|1"));
    }

    @Test
    void noLimite_bloqueiaComStatus429() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);

        ApiException e = assertThrows(ApiException.class, () -> limitador.verificar("a|1"));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
    }

    @Test
    void retryAfter_reflete_otempoRestanteDaJanela() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);
        relogio.avancar(Duration.ofMinutes(5));

        ApiException e = assertThrows(ApiException.class, () -> limitador.verificar("a|1"));

        // Janela de 15 min, já se passaram 5: faltam 10 min = 600 s.
        assertEquals(600L, e.getRetryAfterSegundos());
    }

    @Test
    void aposAJanela_liberaDeNovo() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);
        relogio.avancar(LimitadorDeLogin.JANELA.plusSeconds(1));

        assertDoesNotThrow(() -> limitador.verificar("a|1"));
    }

    @Test
    void falhaDepoisDaJanela_recomecaAContagem() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);
        relogio.avancar(LimitadorDeLogin.JANELA.plusSeconds(1));

        falhar("a|1", 1);

        assertDoesNotThrow(() -> limitador.verificar("a|1"));
    }

    @Test
    void chavesDiferentes_naoSeAfetam() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);

        assertDoesNotThrow(() -> limitador.verificar("a|2"));
        assertDoesNotThrow(() -> limitador.verificar("b|1"));
    }

    @Test
    void limpar_removeOBloqueio() {
        falhar("a|1", LimitadorDeLogin.MAX_FALHAS);

        limitador.limpar("a|1");

        assertDoesNotThrow(() -> limitador.verificar("a|1"));
    }
}
