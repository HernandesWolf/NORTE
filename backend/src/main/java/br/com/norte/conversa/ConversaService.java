package br.com.norte.conversa;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ConversaService {
    private final MensagemConversaRepository mensagens;
    private final OpenAiResponsesClient ia;

    public ConversaService(MensagemConversaRepository mensagens, OpenAiResponsesClient ia) {
        this.mensagens = mensagens;
        this.ia = ia;
    }

    @Transactional(readOnly = true)
    public List<MensagemConversaResponse> listar(UUID usuarioId) {
        return mensagens.findTop100ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId)
                .stream()
                .sorted(Comparator.comparing(MensagemConversa::getCriadoEm)
                        .thenComparing(MensagemConversa::getId))
                .map(MensagemConversaResponse::de)
                .toList();
    }

    /**
     * Persiste primeiro a mensagem do usuário. A chamada externa ocorre fora
     * de uma transação longa; a resposta da IA só é persistida após sucesso.
     */
    public MensagemConversaResponse registrar(UUID usuarioId, String conteudo) {
        MensagemConversa usuario = mensagens.save(
                new MensagemConversa(usuarioId, "USUARIO", conteudo.trim()));

        if (!ia.habilitado()) {
            return MensagemConversaResponse.de(usuario);
        }

        List<MensagemConversa> contexto = mensagens
                .findTop12ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId)
                .stream()
                .sorted(Comparator.comparing(MensagemConversa::getCriadoEm)
                        .thenComparing(MensagemConversa::getId))
                .toList();

        String resposta = ia.responder(contexto);
        MensagemConversa norte = mensagens.save(
                new MensagemConversa(usuarioId, "NORTE", resposta));
        return MensagemConversaResponse.de(norte);
    }

    public ConversaIaStatusResponse statusIa() {
        return new ConversaIaStatusResponse(ia.habilitado(),
                ia.habilitado() ? "OpenAI Responses API" : "desativada");
    }
}
