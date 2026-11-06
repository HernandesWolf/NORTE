package br.com.norte.auth;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "norte.security.jwt")
public record JwtProperties(String secret, Duration accessTokenTtl) {}
