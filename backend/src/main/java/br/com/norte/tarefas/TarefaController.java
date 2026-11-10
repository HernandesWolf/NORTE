package br.com.norte.tarefas;

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
@RequestMapping("/api/v1")
public class TarefaController {
    private final TarefaService tarefas;

    public TarefaController(TarefaService tarefas) {
        this.tarefas = tarefas;
    }

    @GetMapping("/objetivos/{objetivoId}/tarefas")
    public List<TarefaResponse> listar(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID objetivoId) {
        return tarefas.listar(usuarioId(jwt), objetivoId);
    }

    @PostMapping("/objetivos/{objetivoId}/tarefas")
    @ResponseStatus(HttpStatus.CREATED)
    public TarefaResponse criar(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID objetivoId,
                                @Valid @RequestBody TarefaRequest req) {
        return tarefas.criar(usuarioId(jwt), objetivoId, req);
    }

    @GetMapping("/objetivos/{objetivoId}/plano")
    public PlanoResponse plano(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID objetivoId) {
        return tarefas.plano(usuarioId(jwt), objetivoId);
    }

    @PutMapping("/tarefas/{id}")
    public TarefaResponse atualizar(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                                    @Valid @RequestBody TarefaRequest req) {
        return tarefas.atualizar(usuarioId(jwt), id, req);
    }

    @PatchMapping("/tarefas/{id}/conclusao")
    public TarefaResponse concluir(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                                   @Valid @RequestBody TarefaConclusaoRequest req) {
        return tarefas.concluir(usuarioId(jwt), id, req.concluida());
    }

    @DeleteMapping("/tarefas/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        tarefas.excluir(usuarioId(jwt), id);
    }

    private static UUID usuarioId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
