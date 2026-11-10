package br.com.norte.ia;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Regras da conversa com a IA. Ordem importa: primeiro o limite de uso (barato), depois a chamada ao provedor (cara).
 * Nada da conversa é gravado nem registrado em log.
 */
@Service
public class ConversaService {

    private final AiGateway gateway;
    private final LimitadorDeUsoIa limitador;

    public ConversaService(AiGateway gateway, LimitadorDeUsoIa limitador) {
        this.gateway = gateway;
        this.limitador = limitador;
    }

    public ConversaResponse responder(UUID usuarioId, ConversaRequest req) {
        limitador.registrar(usuarioId);

        List<MensagemIa> conversa = new ArrayList<>();
        if (req.historico() != null) {
            for (MensagemRequest anterior : req.historico()) {
                MensagemIa.Papel papel = MensagemIa.Papel.deRotulo(anterior.papel());
                // Alguns provedores exigem que a conversa comece com a pessoa: ignora respostas soltas no início.
                if (conversa.isEmpty() && papel == MensagemIa.Papel.ASSISTENTE) {
                    continue;
                }
                conversa.add(new MensagemIa(papel, anterior.texto().trim()));
            }
        }
        conversa.add(new MensagemIa(MensagemIa.Papel.USUARIO, req.mensagem().trim()));

        return new ConversaResponse(gateway.responder(PromptNorte.INSTRUCAO, conversa));
    }
}
