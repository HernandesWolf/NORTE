package br.com.norte.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Corpo de /auth/refresh e /auth/logout. O limite de tamanho evita aceitar lixo gigante. */
public record RefreshTokenRequest(
        @NotBlank(message = "Informe o refresh token.")
        @Size(max = 200, message = "Refresh token inválido.")
        String refreshToken) {}
