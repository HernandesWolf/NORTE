package br.com.norte.ia;

import java.util.List;

/**
 * Porta de entrada para qualquer provedor de IA. O resto do NORTE só conhece esta interface: trocar de provedor
 * (ou de plano gratuito para pago) é mudar configuração, não código.
 */
public interface AiGateway {

    /**
     * Devolve a resposta da IA para a conversa.
     *
     * @param instrucaoDeSistema regras e tom da IA (veja {@link PromptNorte})
     * @param conversa mensagens em ordem, terminando na última mensagem da pessoa
     * @throws br.com.norte.shared.error.ApiException com mensagem segura para a pessoa, se a IA falhar
     */
    String responder(String instrucaoDeSistema, List<MensagemIa> conversa);
}
