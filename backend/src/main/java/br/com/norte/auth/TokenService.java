package br.com.norte.auth;

import br.com.norte.auth.dto.TokenResponse;
import java.time.Instant;
import java.util.UUID;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

@Service
public class TokenService {

    private final JwtEncoder encoder;
    private final JwtProperties props;

    public TokenService(JwtEncoder encoder, JwtProperties props) {
        this.encoder = encoder;
        this.props = props;
    }

    /** Monta o access token (JWT) e o devolve junto do refresh token já criado por quem chamou. */
    public TokenResponse emitir(UUID usuarioId, String refreshToken) {
        Instant agora = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(JwtConfig.ISSUER)
                .subject(usuarioId.toString())
                .issuedAt(agora)
                .expiresAt(agora.plus(props.accessTokenTtl()))
                .id(UUID.randomUUID().toString())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new TokenResponse(token, refreshToken, "Bearer", props.accessTokenTtl().toSeconds());
    }
}
