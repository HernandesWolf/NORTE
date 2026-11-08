package br.com.norte.auth;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Origens que podem chamar a API a partir de um navegador (ex.: Flutter Web rodando no Chrome).
 * Aceita padrões como {@code http://localhost:*}. Em produção, liste apenas o domínio real do app.
 */
@ConfigurationProperties(prefix = "norte.cors")
public record CorsProperties(List<String> allowedOriginPatterns) {

    public CorsProperties {
        allowedOriginPatterns = allowedOriginPatterns == null ? List.of() : List.copyOf(allowedOriginPatterns);
    }
}
