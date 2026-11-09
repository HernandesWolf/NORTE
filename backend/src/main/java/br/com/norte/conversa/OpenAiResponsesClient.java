package br.com.norte.conversa;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

/**
 * Cliente server-side da Responses API. Sem chave configurada, a integração
 * permanece desativada e nenhuma chamada externa é realizada.
 */
@Component
public class OpenAiResponsesClient {
    private static final int MAX_MENSAGENS = 12;
    private static final int MAX_CARACTERES_POR_MENSAGEM = 1500;

    private final RestClient client;
    private final String apiKey;
    private final String model;
    private final boolean explicitamenteHabilitada;

    public OpenAiResponsesClient(
            RestClient.Builder builder,
            @Value("${norte.ia.openai.api-key:}") String apiKey,
            @Value("${norte.ia.openai.model:gpt-4.1-mini}") String model,
            @Value("${norte.ia.openai.enabled:false}") boolean explicitamenteHabilitada) {
        this.client = builder.baseUrl("https://api.openai.com/v1").build();
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.model = model;
        this.explicitamenteHabilitada = explicitamenteHabilitada;
    }

    public boolean habilitado() {
        return explicitamenteHabilitada && !apiKey.isBlank();
    }

    public String responder(List<MensagemConversa> historico) {
        if (!habilitado()) {
            return null;
        }

        List<Map<String, String>> input = historico.stream()
                .skip(Math.max(0, historico.size() - MAX_MENSAGENS))
                .map(mensagem -> Map.of(
                        "role", mensagem.getPapel().equals("NORTE") ? "assistant" : "user",
                        "content", limitar(mensagem.getConteudo())))
                .toList();

        Map<String, Object> payload = Map.of(
                "model", model,
                "instructions", """
                        Você é o NORTE, um orientador pessoal acolhedor, lúcido e prático.
                        Responda em português brasileiro, com empatia sem infantilizar.
                        Faça uma pergunta por vez quando precisar esclarecer algo.
                        Ajude a pessoa a organizar prioridades e escolher passos realistas.
                        Não invente informações sobre a pessoa nem presuma dados que ela não contou.
                        Não diagnostique condições de saúde nem substitua profissionais.
                        Não crie nem altere objetivos por conta própria: qualquer objetivo deve ser
                        apresentado como proposta e depender de confirmação explícita da pessoa.
                        Seja conciso e não prometa resultados.
                        """,
                "input", input,
                "max_output_tokens", 400);

        try {
            JsonNode response = client.post()
                    .uri("/responses")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + apiKey)
                    .body(payload)
                    .retrieve()
                    .body(JsonNode.class);

            String texto = extrairTexto(response);
            if (texto == null || texto.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY, "A IA não retornou uma resposta válida.");
            }
            return texto.trim();
        } catch (RestClientException e) {
            // Não propaga corpo da resposta nem detalhes que possam expor credenciais.
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY, "Não foi possível obter uma resposta da IA agora.");
        }
    }

    private static String extrairTexto(JsonNode response) {
        if (response == null) return null;

        JsonNode output = response.path("output");
        List<String> partes = new ArrayList<>();
        if (output.isArray()) {
            for (JsonNode item : output) {
                if (!"message".equals(item.path("type").asText())) continue;
                JsonNode content = item.path("content");
                if (!content.isArray()) continue;
                for (JsonNode bloco : content) {
                    if ("output_text".equals(bloco.path("type").asText())) {
                        String texto = bloco.path("text").asText("");
                        if (!texto.isBlank()) partes.add(texto);
                    }
                }
            }
        }
        return partes.isEmpty() ? null : String.join("\n", partes);
    }

    private static String limitar(String texto) {
        if (texto == null || texto.length() <= MAX_CARACTERES_POR_MENSAGEM) return texto;
        return texto.substring(0, MAX_CARACTERES_POR_MENSAGEM);
    }
}
