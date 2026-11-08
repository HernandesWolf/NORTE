package br.com.norte.checkins;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CheckinRepository extends JpaRepository<Checkin, UUID> {

    Optional<Checkin> findByUsuarioIdAndDia(UUID usuarioId, LocalDate dia);

    /**
     * Grava o check-in do dia: cria se não existir, atualiza se já existir, em um único comando atômico.
     * Assim, duas requisições simultâneas do mesmo usuário não geram erro de chave duplicada.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO checkins (id, usuario_id, dia, estado, criado_em, atualizado_em)
            VALUES (gen_random_uuid(), :usuarioId, :dia, :estado, :agora, :agora)
            ON CONFLICT (usuario_id, dia)
            DO UPDATE SET estado = EXCLUDED.estado, atualizado_em = EXCLUDED.atualizado_em
            """, nativeQuery = true)
    int registrar(
            @Param("usuarioId") UUID usuarioId,
            @Param("dia") LocalDate dia,
            @Param("estado") String estado,
            @Param("agora") Instant agora);
}
