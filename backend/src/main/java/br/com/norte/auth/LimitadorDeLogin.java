package br.com.norte.auth;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Limita tentativas de login erradas por chave (e-mail + IP): após {@value #MAX_FALHAS} falhas dentro da janela,
 * bloqueia novas tentativas até a janela terminar.
 *
 * <p>Fica em memória: serve para uma única instância (MVP/piloto). Com várias instâncias, o estado precisará ir
 * para um armazenamento compartilhado (Redis ou banco). A chave inclui o IP para que um desconhecido não consiga
 * trancar a conta de outra pessoa só errando a senha dela.
 */
@Component
public class LimitadorDeLogin {

    static final int MAX_FALHAS = 5;
    static final Duration JANELA = Duration.ofMinutes(15);
    private static final int LIMITE_PARA_FAXINA = 10_000;

    private record Tentativas(int falhas, Instant inicioDaJanela) {}

    private final Clock relogio;
    private final Map<String, Tentativas> porChave = new ConcurrentHashMap<>();

    public LimitadorDeLogin(Clock relogio) {
        this.relogio = relogio;
    }

    /** Lança 429 (com Retry-After) se a chave já estourou o limite. Chamar ANTES de conferir a senha. */
    public void verificar(String chave) {
        Tentativas t = porChave.get(chave);
        if (t == null) {
            return;
        }
        Instant agora = relogio.instant();
        Instant fimDaJanela = t.inicioDaJanela().plus(JANELA);
        if (!agora.isBefore(fimDaJanela)) {
            porChave.remove(chave, t);
            return;
        }
        if (t.falhas() >= MAX_FALHAS) {
            long segundos = Math.max(1, Duration.between(agora, fimDaJanela).toSeconds());
            throw ApiException.muitasTentativas(
                    "Muitas tentativas de entrada. Aguarde alguns minutos e tente novamente.", segundos);
        }
    }

    public void registrarFalha(String chave) {
        Instant agora = relogio.instant();
        if (porChave.size() > LIMITE_PARA_FAXINA) {
            removerExpirados(agora);
        }
        porChave.merge(chave, new Tentativas(1, agora), (atual, nova) -> {
            if (!agora.isBefore(atual.inicioDaJanela().plus(JANELA))) {
                return nova; // janela antiga já passou: recomeça a contagem
            }
            return new Tentativas(atual.falhas() + 1, atual.inicioDaJanela());
        });
    }

    public void limpar(String chave) {
        porChave.remove(chave);
    }

    private void removerExpirados(Instant agora) {
        porChave.entrySet().removeIf(e -> !agora.isBefore(e.getValue().inicioDaJanela().plus(JANELA)));
    }
}
