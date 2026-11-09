package br.com.norte.conversa;

import java.time.Instant;
import java.util.UUID;

public record MensagemConversaResponse(
        UUID id,
        String papel,
        String conteudo,
        Instant criadoEm
) {
    public static MensagemConversaResponse de(MensagemConversa mensagem) {
        return new MensagemConversaResponse(
                mensagem.getId(), mensagem.getPapel(), mensagem.getConteudo(), mensagem.getCriadoEm());
    }
}
