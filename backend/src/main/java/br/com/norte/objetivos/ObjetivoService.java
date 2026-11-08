package br.com.norte.objetivos;

import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ObjetivoService {
    private final ObjetivoRepository repositorio;

    public ObjetivoService(ObjetivoRepository repositorio) {
        this.repositorio = repositorio;
    }

    @Transactional(readOnly = true)
    public List<Objetivo> listar(UUID usuarioId) {
        return repositorio.findAllByUsuarioIdOrderByCriadoEmDesc(usuarioId);
    }

    @Transactional
    public Objetivo criar(UUID usuarioId, ObjetivoRequest req) {
        return repositorio.save(new Objetivo(usuarioId, req.titulo().trim(), limpar(req.descricao())));
    }

    @Transactional
    public Objetivo atualizar(UUID usuarioId, UUID id, ObjetivoRequest req) {
        Objetivo objetivo = obterDoUsuario(usuarioId, id);
        objetivo.atualizar(req.titulo().trim(), limpar(req.descricao()));
        return objetivo;
    }

    @Transactional
    public Objetivo concluir(UUID usuarioId, UUID id, boolean concluido) {
        Objetivo objetivo = obterDoUsuario(usuarioId, id);
        objetivo.definirConclusao(concluido);
        return objetivo;
    }

    @Transactional
    public void excluir(UUID usuarioId, UUID id) {
        repositorio.delete(obterDoUsuario(usuarioId, id));
    }

    private Objetivo obterDoUsuario(UUID usuarioId, UUID id) {
        return repositorio.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Objetivo não encontrado."));
    }

    private static String limpar(String descricao) {
        return descricao == null || descricao.isBlank() ? null : descricao.trim();
    }
}
