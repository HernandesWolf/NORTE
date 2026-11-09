package br.com.norte.conversa;

import jakarta.validation.constraints.NotNull;

public record ConsentimentoIaRequest(@NotNull Boolean consentido) {}
