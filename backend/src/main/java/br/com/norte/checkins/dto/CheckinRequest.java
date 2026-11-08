package br.com.norte.checkins.dto;

import br.com.norte.checkins.EstadoCheckin;
import jakarta.validation.constraints.NotNull;

public record CheckinRequest(@NotNull(message = "Escolha como você está chegando hoje.") EstadoCheckin estado) {}
