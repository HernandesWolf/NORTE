package br.com.norte.auth;

import br.com.norte.auth.dto.LoginRequest;
import br.com.norte.auth.dto.RefreshTokenRequest;
import br.com.norte.auth.dto.RegistroRequest;
import br.com.norte.auth.dto.TokenResponse;
import br.com.norte.auth.dto.UsuarioResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/registro")
    @ResponseStatus(HttpStatus.CREATED)
    public UsuarioResponse registro(@Valid @RequestBody RegistroRequest req) {
        return auth.registrar(req);
    }

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        // Atrás de proxy/balanceador, configure server.forward-headers-strategy para o IP real chegar aqui.
        return auth.login(req, http.getRemoteAddr());
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshTokenRequest req) {
        return auth.renovar(req.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshTokenRequest req) {
        auth.sair(req.refreshToken());
    }
}
