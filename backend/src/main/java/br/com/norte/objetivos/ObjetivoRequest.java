package br.com.norte.objetivos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ObjetivoRequest(
        @NotBlank(message = "Informe o título do objetivo.")
        @Size(max = 120, message = "O título deve ter no máximo 120 caracteres.")
        String titulo,
        @Size(max = 500, message = "A descrição deve ter no máximo 500 caracteres.")
        String descricao) {}
