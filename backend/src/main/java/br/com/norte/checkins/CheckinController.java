package br.com.norte.checkins;

import br.com.norte.checkins.dto.CheckinRequest;
import br.com.norte.checkins.dto.CheckinResponse;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/checkins")
public class CheckinController {

    private final CheckinService checkins;

    public CheckinController(CheckinService checkins) {
        this.checkins = checkins;
    }

    /** 200 com o check-in de hoje, ou 204 se a pessoa ainda não fez. O usuário vem sempre do token. */
    @GetMapping("/hoje")
    public ResponseEntity<CheckinResponse> hoje(@AuthenticationPrincipal Jwt jwt) {
        return checkins.deHoje(usuarioId(jwt))
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PutMapping("/hoje")
    public CheckinResponse registrar(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CheckinRequest req) {
        return checkins.registrarHoje(usuarioId(jwt), req.estado());
    }

    private static UUID usuarioId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
