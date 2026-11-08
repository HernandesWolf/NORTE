package br.com.norte.auth;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "norte.security.jwt")
public record JwtProperties(String secret, Duration accessTokenTtl, Duration refreshTokenTtl) {

    public JwtProperties {
        if (accessTokenTtl == null) {
            accessTokenTtl = Duration.ofMinutes(15);
        }
        if (refreshTokenTtl == null) {
            refreshTokenTtl = Duration.ofDays(30);
        }
    }
}
