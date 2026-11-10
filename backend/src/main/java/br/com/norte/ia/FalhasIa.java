package br.com.norte.ia;

import br.com.norte.shared.error.ApiException;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

/**
 * Traduz falhas dos provedores em erros com mensagem segura. Regras: nunca expor o corpo da resposta do provedor
 * (pode conter detalhes internos), nunca logar a chave nem o texto da conversa; só o status HTTP.
 */
final class FalhasIa {

    private FalhasIa() {}

    static <T> T executar(Logger log, String provedor, Supplier<T> chamada) {
        try {
            return chamada.get();
        } catch (RestClientResponseException e) {
            int status = e.getStatusCode().value();
            log.warn("IA ({}) respondeu HTTP {}", provedor, status);
            if (status == 429) {
                throw ApiException.muitasTentativas(
                        "A IA está recebendo muitos pedidos agora. Tente de novo em instantes.", 30);
            }
            throw indisponivel();
        } catch (RestClientException e) {
            log.warn("IA ({}) não respondeu: {}", provedor, e.getClass().getSimpleName());
            throw indisponivel();
        }
    }

    static ApiException indisponivel() {
        return new ApiException(HttpStatus.BAD_GATEWAY, "Não consegui falar com a IA agora. Tente novamente em instantes.");
    }

    static String textoOuErro(String texto) {
        if (texto == null || texto.isBlank()) {
            throw new ApiException(
                    HttpStatus.BAD_GATEWAY, "Não consegui formular uma resposta para isso. Tente escrever de outro jeito.");
        }
        return texto.trim();
    }
}
