package br.com.norte.conversa;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/conversa")
public class ConversaController {
    private final ConversaService conversa;

    public ConversaController(ConversaService conversa) {
        this.conversa = conversa;
    }

    @GetMapping("/mensagens")
    public List<MensagemConversaResponse> listar(@AuthenticationPrincipal Jwt jwt) {
        return conversa.listar(usuarioId(jwt));
    }

    @PostMapping("/mensagens")
    @ResponseStatus(HttpStatus.CREATED)
    public MensagemConversaResponse registrar(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody MensagemConversaRequest request) {
        return conversa.registrar(usuarioId(jwt), request.conteudo());
    }

    @GetMapping("/ia/status")
    public ConversaIaStatusResponse statusIa(@AuthenticationPrincipal Jwt jwt) {
        return conversa.statusIa(usuarioId(jwt));
    }

    @PutMapping("/ia/consentimento")
    public ConversaIaStatusResponse atualizarConsentimento(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ConsentimentoIaRequest request) {
        return conversa.atualizarConsentimento(usuarioId(jwt), request.consentido());
    }

    private static UUID usuarioId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
