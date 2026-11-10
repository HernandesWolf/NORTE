package br.com.norte.ia;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import org.springframework.http.HttpStatus;

/** Usado quando nenhum provedor foi configurado: a API continua de pé e a conversa avisa que está desligada. */
class GatewayDesligado implements AiGateway {

    @Override
    public String responder(String instrucaoDeSistema, List<MensagemIa> conversa) {
        throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "A conversa com IA ainda não está ativada neste ambiente.");
    }
}
