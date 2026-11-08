package br.com.norte.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
        // O limite de tamanho também protege a memória: o e-mail entra na chave do limitador de tentativas.
        @NotBlank(message = "Informe o e-mail.")
        @Size(max = 255, message = "E-mail muito longo.")
        String email,

        @NotBlank(message = "Informe a senha.")
        @Size(max = 1000, message = "Senha muito longa.")
        String senha) {}
