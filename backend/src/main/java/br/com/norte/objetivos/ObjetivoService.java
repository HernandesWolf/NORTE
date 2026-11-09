package br.com.norte.objetivos;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Regras dos objetivos. Toda consulta e alteração é filtrada pelo dono: se o objetivo existe mas é de outra
 * pessoa, a resposta é a mesma de "não existe" (404), para não revelar a existência de dados alheios.
 */
@Service
public class ObjetivoService {

    private static final String MSG_NAO_ENCONTRADO = "Objetivo não encontrado.";

    private final ObjetivoRepository repositorio;

    public ObjetivoService(ObjetivoRepository repositorio) {
        this.repositorio = repositorio;
    }

    @Transactional(readOnly = true)
    public List<ObjetivoResponse> listar(UUID usuarioId) {
        return repositorio.findAllByUsuarioIdOrderByCriadoEmDesc(usuarioId).stream()
                .map(ObjetivoResponse::de)
                .toList();
    }

    @Transactional
    public ObjetivoResponse criar(UUID usuarioId, ObjetivoRequest req) {
        Objetivo novo = new Objetivo(usuarioId, req.titulo().trim(), limpar(req.descricao()));
        try {
            return ObjetivoResponse.de(repositorio.saveAndFlush(novo));
        } catch (DataIntegrityViolationException e) {
            // Token válido de um usuário que já não existe (conta excluída): a sessão não vale mais.
            throw ApiException.naoAutorizado("Sessão inválida.");
        }
    }

    @Transactional
    public ObjetivoResponse atualizar(UUID usuarioId, UUID id, ObjetivoRequest req) {
        Objetivo objetivo = obterDoUsuario(usuarioId, id);
        objetivo.atualizar(req.titulo().trim(), limpar(req.descricao()));
        // Grava agora para que o @PreUpdate (atualizadoEm) já valha na resposta.
        repositorio.flush();
        return ObjetivoResponse.de(objetivo);
    }

    @Transactional
    public ObjetivoResponse concluir(UUID usuarioId, UUID id, boolean concluido) {
        Objetivo objetivo = obterDoUsuario(usuarioId, id);
        objetivo.definirConclusao(concluido);
        repositorio.flush();
        return ObjetivoResponse.de(objetivo);
    }

    @Transactional
    public void excluir(UUID usuarioId, UUID id) {
        repositorio.delete(obterDoUsuario(usuarioId, id));
    }

    private Objetivo obterDoUsuario(UUID usuarioId, UUID id) {
        return repositorio.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> ApiException.naoEncontrado(MSG_NAO_ENCONTRADO));
    }

    private static String limpar(String descricao) {
        return descricao == null || descricao.isBlank() ? null : descricao.trim();
    }
}
