package br.com.norte.tarefas;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TarefaRepository extends JpaRepository<Tarefa, UUID> {
    List<Tarefa> findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(UUID objetivoId, UUID usuarioId);
    long countByObjetivoIdAndUsuarioId(UUID objetivoId, UUID usuarioId);
    Optional<Tarefa> findByIdAndUsuarioId(UUID id, UUID usuarioId);
}
