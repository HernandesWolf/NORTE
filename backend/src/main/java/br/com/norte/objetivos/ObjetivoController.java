package br.com.norte.objetivos;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/objetivos")
public class ObjetivoController {
    private final ObjetivoService objetivos;

    public ObjetivoController(ObjetivoService objetivos) {
        this.objetivos = objetivos;
    }

    @GetMapping
    public List<ObjetivoResponse> listar(@AuthenticationPrincipal Jwt jwt) {
        return objetivos.listar(usuarioId(jwt));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ObjetivoResponse criar(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody ObjetivoRequest req) {
        return objetivos.criar(usuarioId(jwt), req);
    }

    @PutMapping("/{id}")
    public ObjetivoResponse atualizar(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                                      @Valid @RequestBody ObjetivoRequest req) {
        return objetivos.atualizar(usuarioId(jwt), id, req);
    }

    @PatchMapping("/{id}/conclusao")
    public ObjetivoResponse concluir(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                                     @Valid @RequestBody ConclusaoRequest req) {
        return objetivos.concluir(usuarioId(jwt), id, req.concluido());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        objetivos.excluir(usuarioId(jwt), id);
    }

    private static UUID usuarioId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
