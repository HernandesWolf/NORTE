package br.com.norte.ia;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
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

class GroqGatewayTest {

    private static final String URL = GroqGateway.BASE_URL + "/chat/completions";

    private MockRestServiceServer servidor;
    private GroqGateway gateway;

    @BeforeEach
    void preparar() {
        RestClient.Builder builder = RestClient.builder();
        servidor = MockRestServiceServer.bindTo(builder).build();
        gateway = new GroqGateway(builder.baseUrl(GroqGateway.BASE_URL).build(), "chave-de-teste", "modelo-de-teste");
    }

    private static final List<MensagemIa> CONVERSA = List.of(
            new MensagemIa(MensagemIa.Papel.USUARIO, "Oi"),
            new MensagemIa(MensagemIa.Papel.ASSISTENTE, "Ola, o que pesa hoje?"),
            new MensagemIa(MensagemIa.Papel.USUARIO, "Muita coisa"));

    @Test
    void enviaARequisicaoNoFormatoDoProvedor_eDevolveOTextoSemEspacosNasPontas() {
        servidor.expect(requestTo(URL))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Authorization", "Bearer chave-de-teste"))
                .andExpect(jsonPath("$.model").value("modelo-de-teste"))
                .andExpect(jsonPath("$.max_completion_tokens").value(GroqGateway.MAX_TOKENS))
                .andExpect(jsonPath("$.messages[0].role").value("system"))
                .andExpect(jsonPath("$.messages[0].content").value("regras do norte"))
                .andExpect(jsonPath("$.messages[1].role").value("user"))
                .andExpect(jsonPath("$.messages[2].role").value("assistant"))
                .andExpect(jsonPath("$.messages[3].role").value("user"))
                .andExpect(jsonPath("$.messages[3].content").value("Muita coisa"))
                .andRespond(withSuccess(
                        "{\"choices\":[{\"message\":{\"content\":\"  Estou aqui com voce.  \"}}]}",
                        MediaType.APPLICATION_JSON));

        String resposta = gateway.responder("regras do norte", CONVERSA);

        assertEquals("Estou aqui com voce.", resposta);
        servidor.verify();
    }

    @Test
    void provedorComMuitosPedidos_viraAvisoDeTentarDeNovo429() {
        servidor.expect(requestTo(URL)).andRespond(withTooManyRequests());

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        assertEquals(30L, e.getRetryAfterSegundos());
    }

    @Test
    void erroDoProvedor_viraMensagemSegura_semExporOCorpoDaResposta() {
        servidor.expect(requestTo(URL))
                .andRespond(withServerError().body("detalhe-interno-secreto").contentType(MediaType.TEXT_PLAIN));

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.BAD_GATEWAY, e.getStatus());
        assertFalse(e.getMessage().contains("detalhe-interno-secreto"));
        assertFalse(e.getMessage().contains("chave-de-teste"));
    }

    @Test
    void chaveInvalida401_naoVazaParaAPessoa() {
        servidor.expect(requestTo(URL)).andRespond(withStatus(HttpStatus.UNAUTHORIZED));

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.BAD_GATEWAY, e.getStatus());
    }

    @Test
    void respostaSemTexto_viraErroAmigavel() {
        servidor.expect(requestTo(URL))
                .andRespond(withSuccess("{\"choices\":[{\"message\":{\"content\":\"\"}}]}", MediaType.APPLICATION_JSON));

        ApiException e = assertThrows(ApiException.class, () -> gateway.responder("regras", CONVERSA));

        assertEquals(HttpStatus.BAD_GATEWAY, e.getStatus());
    }

    @Test
    void aChaveVaiNoCabecalho_eNuncaNaUrl() {
        servidor.expect(requestTo(not(containsString("chave-de-teste"))))
                .andRespond(withSuccess("{\"choices\":[{\"message\":{\"content\":\"ok\"}}]}", MediaType.APPLICATION_JSON));

        gateway.responder("regras", CONVERSA);

        servidor.verify();
    }
}
