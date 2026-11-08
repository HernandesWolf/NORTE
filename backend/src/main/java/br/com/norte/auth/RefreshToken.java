package br.com.norte.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/** Sessão renovável de um usuário. Só o hash do token é persistido. */
@Entity
@Table(name = "refresh_tokens")
public class RefreshToken {

    @Id
    private UUID id;

    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "expira_em", nullable = false)
    private Instant expiraEm;

    @Column(name = "revogado_em")
    private Instant revogadoEm;

    protected RefreshToken() {
        // exigido pelo JPA
    }

    public RefreshToken(UUID usuarioId, String tokenHash, Instant criadoEm, Instant expiraEm) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.tokenHash = tokenHash;
        this.criadoEm = criadoEm;
        this.expiraEm = expiraEm;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUsuarioId() {
        return usuarioId;
    }

    public String getTokenHash() {
        return tokenHash;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    public Instant getExpiraEm() {
        return expiraEm;
    }

    public Instant getRevogadoEm() {
        return revogadoEm;
    }
}
