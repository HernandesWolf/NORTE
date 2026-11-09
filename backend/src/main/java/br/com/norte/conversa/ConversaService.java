package br.com.norte.conversa;

import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ConversaService {
    private final MensagemConversaRepository mensagens;

    public ConversaService(MensagemConversaRepository mensagens) {
        this.mensagens = mensagens;
    }

    @Transactional(readOnly = true)
    public List<MensagemConversaResponse> listar(UUID usuarioId) {
        return mensagens.findTop100ByUsuarioIdOrderByCriadoEmAscIdAsc(usuarioId)
                .stream().map(MensagemConversaResponse::de).toList();
    }

    @Transactional
    public MensagemConversaResponse registrar(UUID usuarioId, String conteudo) {
        MensagemConversa mensagem = mensagens.save(
                new MensagemConversa(usuarioId, "USUARIO", conteudo.trim()));
        return MensagemConversaResponse.de(mensagem);
    }
}
