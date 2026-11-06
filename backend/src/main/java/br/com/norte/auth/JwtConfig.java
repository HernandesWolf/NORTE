package br.com.norte.auth;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.nio.charset.StandardCharsets;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

@Configuration
@EnableConfigurationProperties(JwtProperties.class)
public class JwtConfig {

    public static final String ISSUER = "norte";
    private static final String PREFIXO_SEGREDO_DEV = "dev-only-";

    @Bean
    public JwtEncoder jwtEncoder(JwtProperties props, Environment env) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(chave(props, env)));
    }

    @Bean
    public JwtDecoder jwtDecoder(JwtProperties props, Environment env) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(chave(props, env))
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(ISSUER));
        return decoder;
    }

    private SecretKey chave(JwtProperties props, Environment env) {
        String segredo = props.secret();
        if (segredo == null || segredo.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException(
                    "norte.security.jwt.secret (NORTE_JWT_SECRET) precisa ter pelo menos 32 bytes.");
        }
        if (env.acceptsProfiles(Profiles.of("prod")) && segredo.startsWith(PREFIXO_SEGREDO_DEV)) {
            throw new IllegalStateException(
                    "Em produção, defina NORTE_JWT_SECRET com um segredo próprio. O valor de desenvolvimento não é aceito.");
        }
        return new SecretKeySpec(segredo.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }
}
