package br.com.norte.objetivos;

import jakarta.validation.constraints.NotNull;

public record ConclusaoRequest(@NotNull(message = "Informe se o objetivo foi concluído.") Boolean concluido) {}
