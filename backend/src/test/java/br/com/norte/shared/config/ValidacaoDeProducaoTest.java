package br.com.norte.shared.config;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class ValidacaoDeProducaoTest {

    private static MockEnvironment ambienteSeguro() {
        return new MockEnvironment()
                .withProperty("spring.datasource.password", "uma-senha-de-verdade-9f3k2")
                .withProperty("norte.cors.allowed-origin-patterns", "https://app.exemplo.com.br");
    }

    @Test
    void configuracaoSegura_passa() {
        assertDoesNotThrow(() -> ValidacaoDeProducao.validar(ambienteSeguro()));
    }

    @Test
    void variasOrigensReais_passam() {
        MockEnvironment env = ambienteSeguro()
                .withProperty("norte.cors.allowed-origin-patterns", "https://app.exemplo.com.br, https://www.exemplo.com.br");

        assertDoesNotThrow(() -> ValidacaoDeProducao.validar(env));
    }

    @Test
    void senhaDeDesenvolvimentoDoBanco_derrubaAInicializacaoNomeandoAVariavel() {
        MockEnvironment env = ambienteSeguro().withProperty("spring.datasource.password", "norte_dev");

        IllegalStateException e = assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));

        assertTrue(e.getMessage().contains("NORTE_DB_PASSWORD"));
        assertFalse(e.getMessage().contains("NORTE_CORS_ORIGINS"));
    }

    @Test
    void senhaDoBancoEmBranco_derrubaAInicializacao() {
        MockEnvironment env = ambienteSeguro().withProperty("spring.datasource.password", "  ");

        IllegalStateException e = assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));

        assertTrue(e.getMessage().contains("NORTE_DB_PASSWORD"));
    }

    @Test
    void corsApontandoParaLocalhost_derrubaAInicializacao() {
        MockEnvironment env = ambienteSeguro()
                .withProperty("norte.cors.allowed-origin-patterns", "http://localhost:*,http://127.0.0.1:*");

        IllegalStateException e = assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));

        assertTrue(e.getMessage().contains("NORTE_CORS_ORIGINS"));
    }

    @Test
    void corsAbertoParaQualquerOrigem_derrubaAInicializacao() {
        MockEnvironment env = ambienteSeguro().withProperty("norte.cors.allowed-origin-patterns", "*");

        assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));
    }

    @Test
    void localhostMisturadoComOrigemReal_aindaEhRecusado() {
        MockEnvironment env = ambienteSeguro()
                .withProperty("norte.cors.allowed-origin-patterns", "https://app.exemplo.com.br,http://localhost:*");

        assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));
    }

    @Test
    void tudoErrado_listaTodosOsProblemasDeUmaVez() {
        MockEnvironment env = new MockEnvironment()
                .withProperty("spring.datasource.password", "norte_dev")
                .withProperty("norte.cors.allowed-origin-patterns", "http://localhost:*");

        IllegalStateException e = assertThrows(IllegalStateException.class, () -> ValidacaoDeProducao.validar(env));

        assertTrue(e.getMessage().contains("NORTE_DB_PASSWORD"));
        assertTrue(e.getMessage().contains("NORTE_CORS_ORIGINS"));
    }
}
