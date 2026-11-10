package br.com.norte.tarefas;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Corpo para criar ou editar uma tarefa. "dia" é opcional: sem ele, a tarefa fica fora do plano. */
public record TarefaRequest(
        @NotBlank(message = "Informe o título da tarefa.")
        @Size(max = 120, message = "O título deve ter no máximo 120 caracteres.")
        String titulo,
        @Min(value = 1, message = "O dia do plano deve estar entre 1 e 7.")
        @Max(value = 7, message = "O dia do plano deve estar entre 1 e 7.")
        Integer dia) {}
