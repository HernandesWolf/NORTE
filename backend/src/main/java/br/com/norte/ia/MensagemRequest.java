package br.com.norte.ia;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Uma mensagem anterior da conversa, enviada pelo app. */
public record MensagemRequest(
        @NotBlank(message = "Informe quem escreveu a mensagem.")
        @Pattern(regexp = "usuario|assistente", message = "O papel deve ser \"usuario\" ou \"assistente\".")
        String papel,
        @NotBlank(message = "A mensagem do histórico não pode estar vazia.")
        @Size(max = 2000, message = "Cada mensagem do histórico deve ter no máximo 2000 caracteres.")
        String texto) {}
