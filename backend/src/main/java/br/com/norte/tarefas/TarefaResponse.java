package br.com.norte.tarefas;

import java.time.Instant;
import java.util.UUID;

/** O que a API devolve de uma tarefa. Não expõe o dono (o usuário já é identificado pelo token). */
public record TarefaResponse(
        UUID id,
        UUID objetivoId,
        String titulo,
        Integer dia,
        boolean concluida,
        Instant criadoEm,
        Instant atualizadoEm) {

    public static TarefaResponse de(Tarefa t) {
        return new TarefaResponse(
                t.getId(), t.getObjetivoId(), t.getTitulo(), t.getDia(), t.isConcluida(),
                t.getCriadoEm(), t.getAtualizadoEm());
    }
}
