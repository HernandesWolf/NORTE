package br.com.norte.tarefas;

import java.util.List;
import java.util.UUID;

/**
 * Plano de 7 dias de um objetivo: sempre traz os 7 dias (mesmo vazios), mais as tarefas que ainda não têm dia.
 * "total" e "concluidas" contam todas as tarefas do objetivo, inclusive as sem dia.
 */
public record PlanoResponse(
        UUID objetivoId,
        int total,
        int concluidas,
        List<DiaDoPlano> dias,
        List<TarefaResponse> semDia) {

    public record DiaDoPlano(int dia, List<TarefaResponse> tarefas) {}
}
