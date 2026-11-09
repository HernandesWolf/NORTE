package br.com.norte.conversa;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

/**
 * Cliente server-side da Responses API. A integração exige habilitação
 * explícita e chave no ambiente do backend.
 */
@Component
public class OpenAiResponsesClient {
    private static final int MAX_MENSAGENS = 12;
    private static final int MAX_CARACTERES_POR_MENSAGEM = 1500;

    private final RestClient client;
    private final ObjectMapper objectMapper;
    private final String apiKey;
    private final String model;
    private final boolean explicitamenteHabilitada;

    public OpenAiResponsesClient(
            RestClient.Builder builder,
            ObjectMapper objectMapper,
            @Value("${norte.ia.openai.api-key:}") String apiKey,
            @Value("${norte.ia.openai.model:gpt-4.1-mini}") String model,
            @Value("${norte.ia.openai.enabled:false}") boolean explicitamenteHabilitada) {
        this.client = builder.baseUrl("https://api.openai.com/v1").build();
        this.objectMapper = objectMapper;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.model = model;
        this.explicitamenteHabilitada = explicitamenteHabilitada;
    }

    public boolean habilitado() {
        return explicitamenteHabilitada && !apiKey.isBlank();
    }

    public String responder(List<MensagemConversa> historico) {
        return executar(historico, """
                Você é o NORTE, um orientador pessoal acolhedor, lúcido e prático.
                Responda em português brasileiro, com empatia sem infantilizar.
                Faça uma pergunta por vez quando precisar esclarecer algo.
                Ajude a pessoa a organizar prioridades e escolher passos realistas.
                Não invente informações sobre a pessoa nem presuma dados que ela não contou.
                Não diagnostique condições de saúde nem substitua profissionais.
                Não crie nem altere objetivos por conta própria: qualquer objetivo deve ser
                apresentado como proposta e depender de confirmação explícita da pessoa.
                Seja conciso e não prometa resultados.
                """, false, 400);
    }

    public PropostaObjetivoResponse proporObjetivo(List<MensagemConversa> historico) {
        String texto = executar(historico, """
                Analise a conversa e proponha UM objetivo claro, específico e realista,
                coerente com o que a pessoa expressou. Não invente prazos, recursos ou
                compromissos que ela não mencionou. Se não houver intenção suficientemente
                clara de um objetivo, use um título que indique que é necessário conversar
                mais e explique isso na descrição. Responda em português brasileiro.
                Retorne somente um objeto JSON com as chaves "titulo" e "descricao".
                O título deve ter no máximo 120 caracteres e a descrição no máximo 500.
                Esta é apenas uma proposta; nunca diga que ela já foi salva.
                """, true, 220);

        try {
            JsonNode json = objectMapper.readTree(texto);
            String titulo = json.path("titulo").asText("").trim();
            String descricao = json.path("descricao").asText("").trim();
            if (titulo.isBlank() || titulo.length() > 120 || descricao.length() > 500) {
                throw new IllegalArgumentException("Proposta fora dos limites.");
            }
            return new PropostaObjetivoResponse(titulo, descricao);
        } catch (Exception e) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY, "Não foi possível preparar uma proposta de objetivo.");
        }
    }

    private String executar(
            List<MensagemConversa> historico,
            String instrucoes,
            boolean jsonMode,
            int maxOutputTokens) {
        if (!habilitado()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE, "As respostas inteligentes não estão habilitadas.");
        }

        List<Map<String, String>> input = historico.stream()
                .skip(Math.max(0, historico.size() - MAX_MENSAGENS))
                .map(mensagem -> Map.of(
                        "role", mensagem.getPapel().equals("NORTE") ? "assistant" : "user",
                        "content", limitar(mensagem.getConteudo())))
                .toList();

        Map<String, Object> payload = new HashMap<>();
        payload.put("model", model);
        payload.put("instructions", instrucoes);
        payload.put("input", input);
        payload.put("max_output_tokens", maxOutputTokens);
        if (jsonMode) {
            payload.put("text", Map.of("format", Map.of("type", "json_object")));
        }

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
