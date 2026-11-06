package br.com.norte.usuarios;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    private UUID id;

    @Column(name = "email", nullable = false, unique = true)
    private String email;

    @Column(name = "senha_hash", nullable = false)
    private String senhaHash;

    @Column(name = "nome_exibicao", length = 100)
    private String nomeExibicao;

    @Column(name = "criado_em", nullable = false)
    private Instant criadoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    protected Usuario() {
        // exigido pelo JPA
    }

    public Usuario(String email, String senhaHash, String nomeExibicao) {
        this.id = UUID.randomUUID();
        this.email = email;
        this.senhaHash = senhaHash;
        this.nomeExibicao = nomeExibicao;
        this.criadoEm = Instant.now();
        this.atualizadoEm = this.criadoEm;
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getSenhaHash() {
        return senhaHash;
    }

    public String getNomeExibicao() {
        return nomeExibicao;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    public Instant getAtualizadoEm() {
        return atualizadoEm;
    }
}
