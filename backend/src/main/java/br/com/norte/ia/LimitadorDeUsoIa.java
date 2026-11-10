package br.com.norte.ia;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;
import org.springframework.stereotype.Component;

/**
 * Limita quantas mensagens para a IA cada pessoa pode mandar: um teto por minuto (evita rajadas) e um por dia
 * (protege a cota gratuita do provedor, que é da organização inteira). Toda tentativa permitida conta, mesmo que
 * o provedor falhe depois: o objetivo é proteger o custo.
 *
 * <p>Fica em memória: serve para uma única instância (MVP/piloto), como o limitador de login. Com várias instâncias,
 * o estado precisará ir para um armazenamento compartilhado.
 */
@Component
public class LimitadorDeUsoIa {

    private static final Duration JANELA_MINUTO = Duration.ofMinutes(1);
    private static final Duration JANELA_DIA = Duration.ofHours(24);
    private static final int LIMITE_PARA_FAXINA = 10_000;

    private record Uso(Instant inicioMinuto, int noMinuto, Instant inicioDia, int noDia) {}

    private final Clock relogio;
    private final int porMinuto;
    private final int porDia;
    private final Map<UUID, Uso> usos = new ConcurrentHashMap<>();

    public LimitadorDeUsoIa(Clock relogio, IaProperties props) {
        this.relogio = relogio;
        this.porMinuto = props.limitePorMinuto();
        this.porDia = props.limitePorDia();
    }

    /** Conta uma mensagem da pessoa ou lança 429 (com Retry-After) se ela já estourou algum limite. */
    public void registrar(UUID usuarioId) {
        Instant agora = relogio.instant();
        if (usos.size() > LIMITE_PARA_FAXINA) {
            removerExpirados(agora);
        }
        AtomicReference<ApiException> recusa = new AtomicReference<>();
        usos.compute(usuarioId, (id, atual) -> {
            Uso uso = renovarJanelas(atual, agora);
            if (uso.noDia() >= porDia) {
                recusa.set(ApiException.muitasTentativas(
                        "Você chegou ao limite de mensagens por hoje. Tente de novo mais tarde.",
                        segundosAte(agora, uso.inicioDia().plus(JANELA_DIA))));
                return uso;
            }
            if (uso.noMinuto() >= porMinuto) {
                recusa.set(ApiException.muitasTentativas(
                        "Muitas mensagens em pouco tempo. Respire um instante e tente de novo.",
                        segundosAte(agora, uso.inicioMinuto().plus(JANELA_MINUTO))));
                return uso;
            }
            return new Uso(uso.inicioMinuto(), uso.noMinuto() + 1, uso.inicioDia(), uso.noDia() + 1);
        });
        if (recusa.get() != null) {
            throw recusa.get();
        }
    }

    private static Uso renovarJanelas(Uso atual, Instant agora) {
        if (atual == null) {
            return new Uso(agora, 0, agora, 0);
        }
        Instant inicioMinuto = atual.inicioMinuto();
        int noMinuto = atual.noMinuto();
        if (!agora.isBefore(inicioMinuto.plus(JANELA_MINUTO))) {
            inicioMinuto = agora;
            noMinuto = 0;
        }
        Instant inicioDia = atual.inicioDia();
        int noDia = atual.noDia();
        if (!agora.isBefore(inicioDia.plus(JANELA_DIA))) {
            inicioDia = agora;
            noDia = 0;
        }
        return new Uso(inicioMinuto, noMinuto, inicioDia, noDia);
    }

    private static long segundosAte(Instant agora, Instant fim) {
        return Math.max(1, Duration.between(agora, fim).toSeconds());
    }

    private void removerExpirados(Instant agora) {
        usos.entrySet().removeIf(e -> !agora.isBefore(e.getValue().inicioDia().plus(JANELA_DIA)));
    }
}
