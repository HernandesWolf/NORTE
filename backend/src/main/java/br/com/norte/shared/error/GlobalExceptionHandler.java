package br.com.norte.shared.error;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** Converte erros em respostas JSON padronizadas (RFC 7807), sem vazar detalhes internos. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ProblemDetail> aoLancarApiException(ApiException e) {
        ProblemDetail corpo = ProblemDetail.forStatusAndDetail(e.getStatus(), e.getMessage());
        ResponseEntity.BodyBuilder resposta = ResponseEntity.status(e.getStatus());
        if (e.getRetryAfterSegundos() != null) {
            resposta.header(HttpHeaders.RETRY_AFTER, String.valueOf(e.getRetryAfterSegundos()));
        }
        return resposta.body(corpo);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail aoValidarCorpo(MethodArgumentNotValidException e) {
        Map<String, String> erros = new LinkedHashMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> erros.putIfAbsent(f.getField(), f.getDefaultMessage()));
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Dados inválidos.");
        pd.setProperty("erros", erros);
        return pd;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ProblemDetail aoLerCorpoInvalido(HttpMessageNotReadableException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Corpo da requisição inválido.");
    }
}
