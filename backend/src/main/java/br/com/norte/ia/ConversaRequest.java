package br.com.norte.ia;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * Corpo de uma mensagem da conversa. O servidor não guarda a conversa: o app envia o histórico recente junto.
 * Os limites de tamanho existem para controlar o custo de cada chamada à IA.
 */
public record ConversaRequest(
        @NotBlank(message = "Escreva uma mensagem.")
        @Size(max = 2000, message = "A mensagem deve ter no máximo 2000 caracteres.")
        String mensagem,
        @Size(max = 20, message = "O histórico pode ter no máximo 20 mensagens.")
        List<@Valid MensagemRequest> historico) {}
