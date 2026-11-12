package br.com.norte.ia;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.RestClient;

class AiGatewayConfigTest {

    private static AiGateway montar(String provedor, String chave, String modelo) {
        IaProperties props = new IaProperties(provedor, chave, modelo, null, null, null);
        return new AiGatewayConfig().aiGateway(props, RestClient.builder());
    }

    @Test
    void semConfiguracao_aIaFicaDesligada_eAConversaAvisa503() {
        AiGateway gateway = montar(null, null, null);

        assertInstanceOf(GatewayDesligado.class, gateway);
        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", List.of()));
        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, e.getStatus());
    }

    @Test
    void groqComChave_usaOModeloPadraoQuandoNenhumFoiInformado() {
        assertInstanceOf(GroqGateway.class, montar("groq", "chave", ""));
    }

    @Test
    void geminiComChaveEModelo_funciona() {
        assertInstanceOf(GeminiGateway.class, montar("Gemini", "chave", "modelo"));
    }

    @Test
    void provedorSemChave_derrubaAInicializacaoComMensagemClara() {
        IllegalStateException e = assertThrows(IllegalStateException.class, () -> montar("groq", "", ""));

        assertTrue(e.getMessage().contains("NORTE_IA_CHAVE"));
    }

    @Test
    void geminiSemModelo_derrubaAInicializacao() {
        IllegalStateException e = assertThrows(IllegalStateException.class, () -> montar("gemini", "chave", ""));

        assertTrue(e.getMessage().contains("NORTE_IA_MODELO"));
    }

    @Test
    void provedorDesconhecido_derrubaAInicializacao() {
        assertThrows(IllegalStateException.class, () -> montar("provedor-inventado", "chave", "modelo"));
    }

    @Test
    void limitesInvalidosCaemNosPadroes() {
        IaProperties props = new IaProperties("desligado", "", "", 0, -3, 0);

        assertEquals(IaProperties.PADRAO_POR_MINUTO, props.limitePorMinuto());
        assertEquals(IaProperties.PADRAO_POR_DIA, props.limitePorDia());
        assertEquals(IaProperties.PADRAO_GLOBAL_POR_DIA, props.limiteGlobalPorDia());
    }

    @Test
    void aChaveNuncaApareceNoToString() {
        IaProperties props = new IaProperties("groq", "gsk_chave_super_secreta", "modelo", 5, 30, 300);

        assertFalse(props.toString().contains("gsk_chave_super_secreta"));
    }
}
