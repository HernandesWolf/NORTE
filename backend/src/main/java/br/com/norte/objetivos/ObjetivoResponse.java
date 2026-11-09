package br.com.norte.objetivos;

import java.time.Instant;
import java.util.UUID;

/** O que a API devolve de um objetivo. Não expõe o dono (o usuário já é identificado pelo token). */
public record ObjetivoResponse(
        UUID id,
        String titulo,
        String descricao,
        boolean concluido,
        Instant criadoEm,
        Instant atualizadoEm) {

    public static ObjetivoResponse de(Objetivo o) {
        return new ObjetivoResponse(
                o.getId(), o.getTitulo(), o.getDescricao(), o.isConcluido(), o.getCriadoEm(), o.getAtualizadoEm());
    }
}
