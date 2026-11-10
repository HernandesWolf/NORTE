package br.com.norte.ia;

import java.net.http.HttpClient;
import java.time.Duration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

/**
 * Escolhe o provedor de IA pela configuração. Configuração errada derruba a inicialização com uma mensagem clara,
 * em vez de só falhar depois, na primeira conversa de uma pessoa.
 */
@Configuration
@EnableConfigurationProperties(IaProperties.class)
public class AiGatewayConfig {

    @Bean
    public AiGateway aiGateway(IaProperties props, RestClient.Builder builder) {
        return switch (props.provedor()) {
            case "desligado" -> new GatewayDesligado();
            case "groq" -> {
                exigirChave(props);
                String modelo = props.modelo().isBlank() ? GroqGateway.MODELO_PADRAO : props.modelo();
                yield new GroqGateway(cliente(builder, GroqGateway.BASE_URL), props.chave(), modelo);
            }
            case "gemini" -> {
                exigirChave(props);
                if (props.modelo().isBlank()) {
                    throw new IllegalStateException(
                            "NORTE_IA_MODELO é obrigatório com o provedor gemini: copie o nome do modelo no Google AI Studio.");
                }
                yield new GeminiGateway(cliente(builder, GeminiGateway.BASE_URL), props.chave(), props.modelo());
            }
            default -> throw new IllegalStateException(
                    "Provedor de IA desconhecido em NORTE_IA_PROVEDOR. Use: desligado, groq ou gemini.");
        };
    }

    private static void exigirChave(IaProperties props) {
        if (props.chave().isEmpty()) {
            throw new IllegalStateException("NORTE_IA_CHAVE é obrigatória com o provedor " + props.provedor() + ".");
        }
    }

    /** Tempos limite curtos: uma IA lenta não pode segurar as threads da API. */
    private static RestClient cliente(RestClient.Builder builder, String baseUrl) {
        HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        JdkClientHttpRequestFactory fabrica = new JdkClientHttpRequestFactory(http);
        fabrica.setReadTimeout(Duration.ofSeconds(30));
        return builder.clone().baseUrl(baseUrl).requestFactory(fabrica).build();
    }
}
