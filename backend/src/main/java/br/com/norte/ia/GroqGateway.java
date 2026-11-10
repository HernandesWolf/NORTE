package br.com.norte.ia;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

/**
 * Groq (API compatível com a da OpenAI). Plano gratuito sem cartão; a Groq informa que não treina modelos com os
 * dados enviados. Os limites gratuitos valem para a organização inteira, não por usuário do NORTE.
 */
class GroqGateway implements AiGateway {

    static final String BASE_URL = "https://api.groq.com/openai/v1";
    static final String MODELO_PADRAO = "openai/gpt-oss-120b";
    /** Folga para o raciocínio interno do modelo + a resposta (que o prompt pede curta). */
    static final int MAX_TOKENS = 1200;

    private static final Logger LOG = LoggerFactory.getLogger(GroqGateway.class);

    private final RestClient http;
    private final String chave;
    private final String modelo;

    GroqGateway(RestClient http, String chave, String modelo) {
        this.http = http;
        this.chave = chave;
        this.modelo = modelo;
    }

    @Override
    public String responder(String instrucaoDeSistema, List<MensagemIa> conversa) {
        List<Map<String, String>> mensagens = new ArrayList<>();
        mensagens.add(Map.of("role", "system", "content", instrucaoDeSistema));
        for (MensagemIa m : conversa) {
            mensagens.add(Map.of("role", m.papel() == MensagemIa.Papel.USUARIO ? "user" : "assistant", "content", m.texto()));
        }
        Map<String, Object> corpo = Map.of(
                "model", modelo,
                "messages", mensagens,
                "max_completion_tokens", MAX_TOKENS,
                "temperature", 0.7);

        JsonNode resposta = FalhasIa.executar(LOG, "Groq", () -> http.post()
                .uri("/chat/completions")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + chave)
                .contentType(MediaType.APPLICATION_JSON)
                .body(corpo)
                .retrieve()
                .body(JsonNode.class));

        String texto = resposta == null ? "" : resposta.path("choices").path(0).path("message").path("content").asText("");
        return FalhasIa.textoOuErro(texto);
    }
}
