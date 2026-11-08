package br.com.norte.objetivos;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ObjetivoRepository extends JpaRepository<Objetivo, UUID> {
    List<Objetivo> findAllByUsuarioIdOrderByCriadoEmDesc(UUID usuarioId);
    Optional<Objetivo> findByIdAndUsuarioId(UUID id, UUID usuarioId);
}
