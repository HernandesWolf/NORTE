package br.com.norte.shared.status;

import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint público e simples para confirmar que a API está no ar.
 * Não expõe dados de usuário nem detalhes internos.
 */
@RestController
@RequestMapping("/api/v1")
public class StatusController {

    private final String version;

    public StatusController(@Value("${norte.version:0.1.0-SNAPSHOT}") String version) {
        this.version = version;
    }

    @GetMapping("/status")
    public StatusResponse status() {
        return new StatusResponse("NORTE", "ok", version, Instant.now());
    }

    public record StatusResponse(String app, String status, String version, Instant timestamp) {}
}
