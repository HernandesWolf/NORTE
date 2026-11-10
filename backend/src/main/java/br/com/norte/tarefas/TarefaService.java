package br.com.norte.tarefas;

import br.com.norte.objetivos.ObjetivoRepository;
import br.com.norte.shared.error.ApiException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Regras das tarefas e do plano de 7 dias. Segue a mesma regra dos objetivos: tudo é filtrado pelo dono, e o que
 * é de outra pessoa responde 404, igual a "não existe". Para criar ou listar tarefas de um objetivo, o objetivo
 * também precisa ser do usuário.
 */
@Service
public class TarefaService {

    /** Teto de tarefas por objetivo: mantém o plano usável e impede crescimento sem limite. */
    static final int MAX_TAREFAS_POR_OBJETIVO = 50;

    private static final int DIAS_DO_PLANO = 7;
    private static final String MSG_TAREFA_NAO_ENCONTRADA = "Tarefa não encontrada.";
    private static final String MSG_OBJETIVO_NAO_ENCONTRADO = "Objetivo não encontrado.";

    private final TarefaRepository tarefas;
    private final ObjetivoRepository objetivos;

    public TarefaService(TarefaRepository tarefas, ObjetivoRepository objetivos) {
        this.tarefas = tarefas;
        this.objetivos = objetivos;
    }

    @Transactional(readOnly = true)
    public List<TarefaResponse> listar(UUID usuarioId, UUID objetivoId) {
        garantirObjetivoDoUsuario(usuarioId, objetivoId);
        return tarefas.findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(objetivoId, usuarioId).stream()
                .map(TarefaResponse::de)
                .toList();
    }

    @Transactional
    public TarefaResponse criar(UUID usuarioId, UUID objetivoId, TarefaRequest req) {
        garantirObjetivoDoUsuario(usuarioId, objetivoId);
        if (tarefas.countByObjetivoIdAndUsuarioId(objetivoId, usuarioId) >= MAX_TAREFAS_POR_OBJETIVO) {
            throw ApiException.conflito(
                    "Este objetivo já tem " + MAX_TAREFAS_POR_OBJETIVO + " tarefas. Conclua ou exclua alguma antes de criar outra.");
        }
        Tarefa nova = new Tarefa(usuarioId, objetivoId, req.titulo().trim(), req.dia());
        try {
            return TarefaResponse.de(tarefas.saveAndFlush(nova));
        } catch (DataIntegrityViolationException e) {
            // O objetivo ou o usuário deixou de existir entre a checagem e a gravação.
            throw ApiException.naoEncontrado(MSG_OBJETIVO_NAO_ENCONTRADO);
        }
    }

    @Transactional
    public TarefaResponse atualizar(UUID usuarioId, UUID id, TarefaRequest req) {
        Tarefa tarefa = obterDoUsuario(usuarioId, id);
        tarefa.atualizar(req.titulo().trim(), req.dia());
        // Grava agora para que o @PreUpdate (atualizadoEm) já valha na resposta.
        tarefas.flush();
        return TarefaResponse.de(tarefa);
    }

    @Transactional
    public TarefaResponse concluir(UUID usuarioId, UUID id, boolean concluida) {
        Tarefa tarefa = obterDoUsuario(usuarioId, id);
        tarefa.definirConclusao(concluida);
        tarefas.flush();
        return TarefaResponse.de(tarefa);
    }

    @Transactional
    public void excluir(UUID usuarioId, UUID id) {
        tarefas.delete(obterDoUsuario(usuarioId, id));
    }

    @Transactional(readOnly = true)
    public PlanoResponse plano(UUID usuarioId, UUID objetivoId) {
        garantirObjetivoDoUsuario(usuarioId, objetivoId);
        List<TarefaResponse> todas = tarefas.findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(objetivoId, usuarioId)
                .stream()
                .map(TarefaResponse::de)
                .toList();

        List<PlanoResponse.DiaDoPlano> dias = new ArrayList<>(DIAS_DO_PLANO);
        for (int dia = 1; dia <= DIAS_DO_PLANO; dia++) {
            int diaAtual = dia;
            dias.add(new PlanoResponse.DiaDoPlano(
                    diaAtual, todas.stream().filter(t -> t.dia() != null && t.dia() == diaAtual).toList()));
        }
        List<TarefaResponse> semDia = todas.stream().filter(t -> t.dia() == null).toList();
        int concluidas = (int) todas.stream().filter(TarefaResponse::concluida).count();

        return new PlanoResponse(objetivoId, todas.size(), concluidas, dias, semDia);
    }

    private Tarefa obterDoUsuario(UUID usuarioId, UUID id) {
        return tarefas.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> ApiException.naoEncontrado(MSG_TAREFA_NAO_ENCONTRADA));
    }

    private void garantirObjetivoDoUsuario(UUID usuarioId, UUID objetivoId) {
        objetivos.findByIdAndUsuarioId(objetivoId, usuarioId)
                .orElseThrow(() -> ApiException.naoEncontrado(MSG_OBJETIVO_NAO_ENCONTRADO));
    }
}
