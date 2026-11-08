package br.com.norte.checkins;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** Check-in de um usuário em um dia. A gravação é feita por upsert no repositório; aqui só lemos. */
@Entity
@Table(name = "checkins")
public class Checkin {

    @Id
    private UUID id;

    @Column(name = "usuario_id", nullable = false)
    private UUID usuarioId;

    @Column(name = "dia", nullable = false)
    private LocalDate dia;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 20)
    private EstadoCheckin estado;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    protected Checkin() {
        // exigido pelo JPA
    }

    public Checkin(UUID usuarioId, LocalDate dia, EstadoCheckin estado, Instant agora) {
        this.id = UUID.randomUUID();
        this.usuarioId = usuarioId;
        this.dia = dia;
        this.estado = estado;
        this.criadoEm = agora;
        this.atualizadoEm = agora;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUsuarioId() {
        return usuarioId;
    }

    public LocalDate getDia() {
        return dia;
    }

    public EstadoCheckin getEstado() {
        return estado;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    public Instant getAtualizadoEm() {
        return atualizadoEm;
    }
}
