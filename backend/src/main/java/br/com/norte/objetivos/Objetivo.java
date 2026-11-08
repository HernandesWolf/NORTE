package br.com.norte.objetivos;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "objetivos")
public class Objetivo {
    @Id
    private UUID id;

    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;

    @Column(nullable = false, length = 120)
    private String titulo;

    @Column(length = 500)
    private String descricao;

    @Column(nullable = false)
    private boolean concluido;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    protected Objetivo() {}

    public Objetivo(UUID usuarioId, String titulo, String descricao) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.titulo = titulo;
        this.descricao = descricao;
        this.concluido = false;
        this.criadoEm = Instant.now();
        this.atualizadoEm = this.criadoEm;
    }

    public void atualizar(String titulo, String descricao) {
        this.titulo = titulo;
        this.descricao = descricao;
    }

    public void definirConclusao(boolean concluido) {
        this.concluido = concluido;
    }

    @PreUpdate
    void atualizarData() {
        this.atualizadoEm = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }
    public String getTitulo() { return titulo; }
    public String getDescricao() { return descricao; }
    public boolean isConcluido() { return concluido; }
    public Instant getCriadoEm() { return criadoEm; }
    public Instant getAtualizadoEm() { return atualizadoEm; }
}
