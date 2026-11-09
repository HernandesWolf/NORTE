package br.com.norte.conversa;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mensagens_conversa")
public class MensagemConversa {
    @Id
    private UUID id;

    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;

    @Column(nullable = false, length = 20)
    private String papel;

    @Column(nullable = false, length = 4000)
    private String conteudo;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    protected MensagemConversa() {}

    public MensagemConversa(UUID usuarioId, String papel, String conteudo) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.papel = papel;
        this.conteudo = conteudo;
        this.criadoEm = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }
    public String getPapel() { return papel; }
    public String getConteudo() { return conteudo; }
    public Instant getCriadoEm() { return criadoEm; }
}
