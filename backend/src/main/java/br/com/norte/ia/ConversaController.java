package br.com.norte.ia;

import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/conversa")
public class ConversaController {
    private final ConversaService conversa;

    public ConversaController(ConversaService conversa) {
        this.conversa = conversa;
    }

    @PostMapping
    public ConversaResponse responder(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ConversaRequest req) {
        return conversa.responder(UUID.fromString(jwt.getSubject()), req);
    }
}
