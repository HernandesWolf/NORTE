package br.com.norte.conversa;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MensagemConversaRepository extends JpaRepository<MensagemConversa, UUID> {
    List<MensagemConversa> findTop100ByUsuarioIdOrderByCriadoEmAscIdAsc(UUID usuarioId);
}
