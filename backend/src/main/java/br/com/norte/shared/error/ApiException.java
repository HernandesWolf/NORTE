package br.com.norte.shared.error;

import org.springframework.http.HttpStatus;

/** Erro de negócio com status HTTP associado. A mensagem é segura para ser exibida ao usuário. */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    /** Preenchido apenas em respostas 429: quantos segundos o cliente deve esperar. */
    private final Long retryAfterSegundos;

    public ApiException(HttpStatus status, String mensagem) {
        this(status, mensagem, null);
    }

    public ApiException(HttpStatus status, String mensagem, Long retryAfterSegundos) {
        super(mensagem);
        this.status = status;
        this.retryAfterSegundos = retryAfterSegundos;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public Long getRetryAfterSegundos() {
        return retryAfterSegundos;
    }

    public static ApiException requisicaoInvalida(String mensagem) {
        return new ApiException(HttpStatus.BAD_REQUEST, mensagem);
    }

    public static ApiException naoAutorizado(String mensagem) {
        return new ApiException(HttpStatus.UNAUTHORIZED, mensagem);
    }

    public static ApiException naoEncontrado(String mensagem) {
        return new ApiException(HttpStatus.NOT_FOUND, mensagem);
    }

    public static ApiException conflito(String mensagem) {
        return new ApiException(HttpStatus.CONFLICT, mensagem);
    }

    public static ApiException muitasTentativas(String mensagem, long retryAfterSegundos) {
        return new ApiException(HttpStatus.TOO_MANY_REQUESTS, mensagem, retryAfterSegundos);
    }
}
