package br.com.norte.tarefas;

import jakarta.validation.constraints.NotNull;

public record TarefaConclusaoRequest(@NotNull(message = "Informe se a tarefa foi concluída.") Boolean concluida) {}
