package br.com.norte.conversa;

public record ConversaIaStatusResponse(
        boolean habilitada,
        String provedor,
        boolean consentimentoUsuario
) {}
