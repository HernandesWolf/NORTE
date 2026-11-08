package br.com.norte.auth;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /**
     * Revoga o token só se ainda estiver ativo, em um único UPDATE atômico.
     * Retorna 1 se este chamador "ganhou" a revogação e 0 se outro já tinha revogado
     * (é isso que impede dois refreshes simultâneos de gerarem duas sessões novas).
     */
    @Modifying(clearAutomatically = true)
    @Query("update RefreshToken r set r.revogadoEm = :agora where r.id = :id and r.revogadoEm is null")
    int revogarSeAtivo(@Param("id") UUID id, @Param("agora") Instant agora);

    /** Derruba todas as sessões ativas do usuário (usado quando detectamos reuso de token). */
    @Modifying(clearAutomatically = true)
    @Query("update RefreshToken r set r.revogadoEm = :agora where r.usuarioId = :usuarioId and r.revogadoEm is null")
    int revogarTodosDoUsuario(@Param("usuarioId") UUID usuarioId, @Param("agora") Instant agora);
}
