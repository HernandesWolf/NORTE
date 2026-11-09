package br.com.norte.conversa;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MensagemConversaRequest(
        @NotBlank @Size(max = 4000) String conteudo
) {}
