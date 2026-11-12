package br.com.norte.auth;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Limita quantos cadastros cada IP pode fazer por hora. Sem isso, qualquer pessoa cria contas em massa: cada conta
 * gasta CPU (BCrypt) e ganha uma cota própria de mensagens da IA, o que esgotaria a cota gratuita de todo mundo.
 *
 * <p>Toda tentativa conta, mesmo as que depois falham (e-mail repetido, por exemplo): o objetivo é proteger o
 * custo, não punir quem errou. O limite vem de {@code norte.security.cadastros-por-hora} (padrão: 5).
 *
 * <p>Fica em memória, como os outros limitadores: serve para uma única instância (MVP/piloto). Atrás de proxy, o IP
 * só é o real se {@code server.forward-headers-strategy} estiver configurado; sem isso todo mundo parece ter o mesmo
 * IP e o limite vira coletivo.
 */
@Component
public class LimitadorDeCadastro {

    static final Duration JANELA = Duration.ofHours(1);
    private static final int LIMITE_PARA_FAXINA = 10_000;

    private record Janela(Instant inicio, int usos) {}

    private final Clock relogio;
    private final int maximoPorJanela;
    private final Map<String, Janela> porIp = new ConcurrentHashMap<>();

    public LimitadorDeCadastro(Clock relogio, @Value("${norte.security.cadastros-por-hora:5}") int maximoPorJanela) {
        this.relogio = relogio;
        this.maximoPorJanela = maximoPorJanela > 0 ? maximoPorJanela : 5;
    }

    /** Conta um cadastro deste IP ou lança 429 (com Retry-After) se ele já estourou o limite da hora. */
    public void registrar(String ip) {
        Instant agora = relogio.instant();
        if (porIp.size() > LIMITE_PARA_FAXINA) {
            removerExpirados(agora);
        }
        AtomicReference<ApiException> recusa = new AtomicReference<>();
        porIp.compute(ip, (chave, atual) -> {
            Janela janela = atual == null || !agora.isBefore(atual.inicio().plus(JANELA))
                    ? new Janela(agora, 0)
                    : atual;
            if (janela.usos() >= maximoPorJanela) {
                long segundos = Math.max(1, Duration.between(agora, janela.inicio().plus(JANELA)).toSeconds());
                recusa.set(ApiException.muitasTentativas(
                        "Muitos cadastros a partir desta rede. Tente novamente mais tarde.", segundos));
                return janela;
            }
            return new Janela(janela.inicio(), janela.usos() + 1);
        });
        if (recusa.get() != null) {
            throw recusa.get();
        }
    }

    private void removerExpirados(Instant agora) {
        porIp.entrySet().removeIf(e -> !agora.isBefore(e.getValue().inicio().plus(JANELA)));
    }
}
