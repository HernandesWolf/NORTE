package br.com.norte.tarefas;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "tarefas")
public class Tarefa {
    @Id
    private UUID id;

    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;

    @Column(name = "objetivo_id", nullable = false)
    private UUID objetivoId;

    @Column(nullable = false, length = 120)
    private String titulo;

    /** Dia do plano de 7 dias (1 a 7); nulo quando a tarefa ainda não tem dia. */
    @Column
    private Integer dia;

    @Column(nullable = false)
    private boolean concluida;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    protected Tarefa() {}

    public Tarefa(UUID usuarioId, UUID objetivoId, String titulo, Integer dia) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.objetivoId = objetivoId;
        this.titulo = titulo;
        this.dia = dia;
        this.concluida = false;
        this.criadoEm = Instant.now();
        this.atualizadoEm = this.criadoEm;
    }

    public void atualizar(String titulo, Integer dia) {
        this.titulo = titulo;
        this.dia = dia;
    }

    public void definirConclusao(boolean concluida) {
        this.concluida = concluida;
    }

    @PreUpdate
    void atualizarData() {
        this.atualizadoEm = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getUsuarioId() { return usuarioId; }
    public UUID getObjetivoId() { return objetivoId; }
    public String getTitulo() { return titulo; }
    public Integer getDia() { return dia; }
    public boolean isConcluida() { return concluida; }
    public Instant getCriadoEm() { return criadoEm; }
    public Instant getAtualizadoEm() { return atualizadoEm; }
}
