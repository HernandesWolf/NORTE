package br.com.norte.ia;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Limita o uso da IA em três níveis: um teto por minuto para cada pessoa (evita rajadas), um por dia para cada
 * pessoa e um teto por dia somando todo mundo. O global existe porque a cota gratuita do provedor é da organização
 * inteira: sem ele, várias contas juntas esgotariam a cota de todas as outras. Toda tentativa permitida conta,
 * mesmo que o provedor falhe depois: o objetivo é proteger o custo. Tentativa recusada não gasta cota de ninguém.
 *
 * <p>Fica em memória: serve para uma única instância (MVP/piloto), como o limitador de login. Com várias instâncias,
 * o estado precisará ir para um armazenamento compartilhado.
 *
 * <p>{@link #registrar(UUID)} é {@code synchronized}: a decisão olha o contador da pessoa e o global ao mesmo
 * tempo, e só incrementa os dois quando ambos permitem. É uma operação de memória de poucos microssegundos, então
 * a trava não pesa no volume de um piloto.
 */
@Component
public class LimitadorDeUsoIa {

    private static final Duration JANELA_MINUTO = Duration.ofMinutes(1);
    private static final Duration JANELA_DIA = Duration.ofHours(24);
    private static final int LIMITE_PARA_FAXINA = 10_000;

    private record Uso(Instant inicioMinuto, int noMinuto, Instant inicioDia, int noDia) {}

    private record UsoGlobal(Instant inicioDia, int noDia) {}

    private final Clock relogio;
    private final int porMinuto;
    private final int porDia;
    private final int globalPorDia;
    private final Map<UUID, Uso> usos = new HashMap<>();
    private UsoGlobal global;

    public LimitadorDeUsoIa(Clock relogio, IaProperties props) {
        this.relogio = relogio;
        this.porMinuto = props.limitePorMinuto();
        this.porDia = props.limitePorDia();
        this.globalPorDia = props.limiteGlobalPorDia();
    }

    /** Conta uma mensagem da pessoa ou lança 429 (com Retry-After) se ela, ou o total do dia, já estourou o limite. */
    public synchronized void registrar(UUID usuarioId) {
        Instant agora = relogio.instant();
        if (usos.size() > LIMITE_PARA_FAXINA) {
            removerExpirados(agora);
        }

        Uso uso = renovarJanelas(usos.get(usuarioId), agora);
        UsoGlobal geral = renovarGlobal(global, agora);
        // Guarda as janelas já renovadas mesmo se a tentativa for recusada, sem contar a mensagem.
        usos.put(usuarioId, uso);
        global = geral;

        if (uso.noDia() >= porDia) {
            throw ApiException.muitasTentativas(
                    "Você chegou ao limite de mensagens por hoje. Tente de novo mais tarde.",
                    segundosAte(agora, uso.inicioDia().plus(JANELA_DIA)));
        }
        if (uso.noMinuto() >= porMinuto) {
            throw ApiException.muitasTentativas(
                    "Muitas mensagens em pouco tempo. Respire um instante e tente de novo.",
                    segundosAte(agora, uso.inicioMinuto().plus(JANELA_MINUTO)));
        }
        if (geral.noDia() >= globalPorDia) {
            throw ApiException.muitasTentativas(
                    "A conversa está com muita procura e chegou ao limite de hoje. Tente de novo mais tarde.",
                    segundosAte(agora, geral.inicioDia().plus(JANELA_DIA)));
        }

        usos.put(usuarioId, new Uso(uso.inicioMinuto(), uso.noMinuto() + 1, uso.inicioDia(), uso.noDia() + 1));
        global = new UsoGlobal(geral.inicioDia(), geral.noDia() + 1);
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

    private static UsoGlobal renovarGlobal(UsoGlobal atual, Instant agora) {
        if (atual == null || !agora.isBefore(atual.inicioDia().plus(JANELA_DIA))) {
            return new UsoGlobal(agora, 0);
        }
        return atual;
    }

    private static long segundosAte(Instant agora, Instant fim) {
        return Math.max(1, Duration.between(agora, fim).toSeconds());
    }

    private void removerExpirados(Instant agora) {
        usos.entrySet().removeIf(e -> !agora.isBefore(e.getValue().inicioDia().plus(JANELA_DIA)));
    }
}
