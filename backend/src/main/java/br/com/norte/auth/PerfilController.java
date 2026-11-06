package br.com.norte.auth;

import br.com.norte.auth.dto.UsuarioResponse;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class PerfilController {

    private final AuthService auth;

    public PerfilController(AuthService auth) {
        this.auth = auth;
    }

    /** O usuário vem sempre do token, nunca de um parâmetro: ninguém consulta o perfil de outra pessoa. */
    @GetMapping("/me")
    public UsuarioResponse me(@AuthenticationPrincipal Jwt jwt) {
        return auth.perfil(UUID.fromString(jwt.getSubject()));
    }
}
