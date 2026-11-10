package br.com.norte.ia;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

/**
 * Google Gemini (API generateContent). No plano gratuito o Google pode usar o conteúdo enviado para melhorar seus
 * produtos: ótimo para desenvolvimento com dados fictícios, mas não para pessoas reais. A chave vai no cabeçalho
 * (nunca na URL, que costuma aparecer em logs).
 */
class GeminiGateway implements AiGateway {

    static final String BASE_URL = "https://generativelanguage.googleapis.com";
    static final int MAX_TOKENS = 1200;

    private static final Logger LOG = LoggerFactory.getLogger(GeminiGateway.class);

    private final RestClient http;
    private final String chave;
    private final String modelo;

    GeminiGateway(RestClient http, String chave, String modelo) {
        this.http = http;
        this.chave = chave;
        this.modelo = modelo;
    }

    @Override
    public String responder(String instrucaoDeSistema, List<MensagemIa> conversa) {
        List<Map<String, Object>> conteudos = new ArrayList<>();
        for (MensagemIa m : conversa) {
            conteudos.add(Map.of(
                    "role", m.papel() == MensagemIa.Papel.USUARIO ? "user" : "model",
                    "parts", List.of(Map.of("text", m.texto()))));
        }
        Map<String, Object> corpo = Map.of(
                "systemInstruction", Map.of("parts", List.of(Map.of("text", instrucaoDeSistema))),
                "contents", conteudos,
                "generationConfig", Map.of("maxOutputTokens", MAX_TOKENS, "temperature", 0.7));

        JsonNode resposta = FalhasIa.executar(LOG, "Gemini", () -> http.post()
                .uri("/v1beta/models/{modelo}:generateContent", modelo)
                .header("x-goog-api-key", chave)
                .contentType(MediaType.APPLICATION_JSON)
                .body(corpo)
                .retrieve()
                .body(JsonNode.class));

        StringBuilder texto = new StringBuilder();
        if (resposta != null) {
            for (JsonNode parte : resposta.path("candidates").path(0).path("content").path("parts")) {
                texto.append(parte.path("text").asText(""));
            }
        }
        return FalhasIa.textoOuErro(texto.toString());
    }
}
