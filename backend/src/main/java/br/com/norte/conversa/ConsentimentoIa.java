package br.com.norte.conversa;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "consentimentos_ia")
public class ConsentimentoIa {
    public static final String VERSAO_ATUAL = "2026-11-09";

    @Id
    @Column(name = "usuario_id")
    private UUID usuarioId;

    @Column(nullable = false)
    private boolean habilitado;

    @Column(nullable = false, length = 30)
    private String versao;

    @Column(name = "aceito_em")
    private Instant aceitoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    protected ConsentimentoIa() {}

    public ConsentimentoIa(UUID usuarioId, boolean habilitado) {
        this.usuarioId = usuarioId;
        atualizar(habilitado);
    }

    public void atualizar(boolean habilitado) {
        this.habilitado = habilitado;
        this.versao = VERSAO_ATUAL;
        this.aceitoEm = habilitado ? Instant.now() : null;
        this.atualizadoEm = Instant.now();
    }

    public UUID getUsuarioId() { return usuarioId; }
    public boolean isHabilitado() { return habilitado; }
    public String getVersao() { return versao; }
    public Instant getAceitoEm() { return aceitoEm; }
    public Instant getAtualizadoEm() { return atualizadoEm; }
}
