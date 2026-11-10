package br.com.norte.ia;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withTooManyRequests;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class GeminiGatewayTest {

    private static final String FINAL_DA_URL = "/v1beta/models/modelo-de-teste:generateContent";

    private MockRestServiceServer servidor;
    private GeminiGateway gateway;

    @BeforeEach
    void preparar() {
        RestClient.Builder builder = RestClient.builder();
        servidor = MockRestServiceServer.bindTo(builder).build();
        gateway = new GeminiGateway(builder.baseUrl(GeminiGateway.BASE_URL).build(), "chave-de-teste", "modelo-de-teste");
    }

    private static final List<MensagemIa> CONVERSA = List.of(
            new MensagemIa(MensagemIa.Papel.USUARIO, "Oi"),
            new MensagemIa(MensagemIa.Papel.ASSISTENTE, "Ola, o que pesa hoje?"),
            new MensagemIa(MensagemIa.Papel.USUARIO, "Muita coisa"));

    @Test
    void enviaARequisicaoNoFormatoDoGemini_eJuntaAsPartesDaResposta() {
        servidor.expect(requestTo(endsWith(FINAL_DA_URL)))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("x-goog-api-key", "chave-de-teste"))
                .andExpect(jsonPath("$.systemInstruction.parts[0].text").value("regras do norte"))
                .andExpect(jsonPath("$.contents[0].role").value("user"))
                .andExpect(jsonPath("$.contents[1].role").value("model"))
                .andExpect(jsonPath("$.contents[2].role").value("user"))
                .andExpect(jsonPath("$.contents[2].parts[0].text").value("Muita coisa"))
                .andExpect(jsonPath("$.generationConfig.maxOutputTokens").value(GeminiGateway.MAX_TOKENS))
                .andRespond(withSuccess(
                        "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"Estou \"},{\"text\":\"aqui.\"}]}}]}",
                        MediaType.APPLICATION_JSON));

        String resposta = gateway.responder("regras do norte", CONVERSA);

        assertEquals("Estou aqui.", resposta);
        servidor.verify();
    }

    @Test
    void aChaveVaiNoCabecalho_eNuncaNaUrl() {
        servidor.expect(requestTo(not(containsString("chave-de-teste"))))
                .andRespond(withSuccess(
                        "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"ok\"}]}}]}", MediaType.APPLICATION_JSON));

        gateway.responder("regras", CONVERSA);

        servidor.verify();
    }

    @Test
    void provedorComMuitosPedidos_viraAvisoDeTentarDeNovo429() {
        servidor.expect(requestTo(endsWith(FINAL_DA_URL))).andRespond(withTooManyRequests());

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertEquals(30L, e.getRetryAfterSegundos());
    }

    @Test
    void erroDoProvedor_viraMensagemSegura_semExporOCorpoDaResposta() {
        servidor.expect(requestTo(endsWith(FINAL_DA_URL)))
                .andRespond(withServerError().body("detalhe-interno-secreto").contentType(MediaType.TEXT_PLAIN));

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.BAD_GATEWAY, e.getStatus());
        assertFalse(e.getMessage().contains("detalhe-interno-secreto"));
    }

    @Test
    void respostaBloqueadaOuSemCandidatos_viraErroAmigavel() {
        servidor.expect(requestTo(endsWith(FINAL_DA_URL)))
                .andRespond(withSuccess("{\"promptFeedback\":{\"blockReason\":\"SAFETY\"}}", MediaType.APPLICATION_JSON));

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.BAD_GATEWAY, e.getStatus());
    }
}
