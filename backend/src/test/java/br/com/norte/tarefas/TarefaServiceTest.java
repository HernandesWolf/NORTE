package br.com.norte.tarefas;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.com.norte.objetivos.Objetivo;
import br.com.norte.objetivos.ObjetivoRepository;
import br.com.norte.shared.error.ApiException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;

@ExtendWith(MockitoExtension.class)
class TarefaServiceTest {

    @Mock
    private TarefaRepository tarefas;

    @Mock
    private ObjetivoRepository objetivos;

    @InjectMocks
    private TarefaService servico;

    private final UUID dono = UUID.randomUUID();
    private final UUID intruso = UUID.randomUUID();
    private final UUID objetivoId = UUID.randomUUID();

    private void objetivoExisteParaODono() {
        when(objetivos.findByIdAndUsuarioId(objetivoId, dono))
                .thenReturn(Optional.of(new Objetivo(dono, "Meta", null)));
    }

    // ---------- criar ----------

    @Test
    void criar_limpaEspacosEGravaParaODonoDoToken() {
        objetivoExisteParaODono();
        when(tarefas.countByObjetivoIdAndUsuarioId(objetivoId, dono)).thenReturn(0L);
        when(tarefas.saveAndFlush(any(Tarefa.class))).thenAnswer(i -> i.getArgument(0));

        TarefaResponse resposta = servico.criar(dono, objetivoId, new TarefaRequest("  Estudar 1h  ", 3));

        assertEquals("Estudar 1h", resposta.titulo());
        assertEquals(3, resposta.dia());
        assertFalse(resposta.concluida());
        ArgumentCaptor<Tarefa> capturada = ArgumentCaptor.forClass(Tarefa.class);
        verify(tarefas).saveAndFlush(capturada.capture());
        assertEquals(dono, capturada.getValue().getUsuarioId());
        assertEquals(objetivoId, capturada.getValue().getObjetivoId());
    }

    @Test
    void criar_semDia_ficaForaDoPlano() {
        objetivoExisteParaODono();
        when(tarefas.countByObjetivoIdAndUsuarioId(objetivoId, dono)).thenReturn(0L);
        when(tarefas.saveAndFlush(any(Tarefa.class))).thenAnswer(i -> i.getArgument(0));

        TarefaResponse resposta = servico.criar(dono, objetivoId, new TarefaRequest("Ler", null));

        assertNull(resposta.dia());
    }

    @Test
    void criar_objetivoDeOutroUsuario_retorna404ENaoGrava() {
        when(objetivos.findByIdAndUsuarioId(objetivoId, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.criar(intruso, objetivoId, new TarefaRequest("Invadida", 1)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(tarefas, never()).saveAndFlush(any());
    }

    @Test
    void criar_noLimiteDeTarefas_retorna409ENaoGrava() {
        objetivoExisteParaODono();
        when(tarefas.countByObjetivoIdAndUsuarioId(objetivoId, dono))
                .thenReturn((long) TarefaService.MAX_TAREFAS_POR_OBJETIVO);

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.criar(dono, objetivoId, new TarefaRequest("Mais uma", null)));

        assertEquals(HttpStatus.CONFLICT, erro.getStatus());
        verify(tarefas, never()).saveAndFlush(any());
    }

    @Test
    void criar_objetivoRemovidoNoMeioDoCaminho_retorna404() {
        objetivoExisteParaODono();
        when(tarefas.countByObjetivoIdAndUsuarioId(objetivoId, dono)).thenReturn(0L);
        when(tarefas.saveAndFlush(any(Tarefa.class))).thenThrow(new DataIntegrityViolationException("fk"));

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.criar(dono, objetivoId, new TarefaRequest("Meta", 1)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
    }

    // ---------- listar ----------

    @Test
    void listar_consultaSomenteTarefasDoObjetivoEDoUsuario() {
        objetivoExisteParaODono();
        when(tarefas.findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(objetivoId, dono))
                .thenReturn(List.of(new Tarefa(dono, objetivoId, "Uma", 1)));

        List<TarefaResponse> lista = servico.listar(dono, objetivoId);

        assertEquals(1, lista.size());
        assertEquals("Uma", lista.get(0).titulo());
        verify(tarefas, never()).findAll();
    }

    @Test
    void listar_objetivoDeOutroUsuario_retorna404() {
        when(objetivos.findByIdAndUsuarioId(objetivoId, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class, () -> servico.listar(intruso, objetivoId));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(tarefas, never()).findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(any(), any());
    }

    // ---------- operações do dono ----------

    @Test
    void atualizar_doDono_alteraTituloEDia() {
        Tarefa existente = new Tarefa(dono, objetivoId, "Antiga", 1);
        when(tarefas.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        TarefaResponse resposta = servico.atualizar(dono, existente.getId(), new TarefaRequest(" Nova ", null));

        assertEquals("Nova", resposta.titulo());
        assertNull(resposta.dia());
    }

    @Test
    void concluir_doDono_marcaEDesmarca() {
        Tarefa existente = new Tarefa(dono, objetivoId, "Tarefa", 2);
        when(tarefas.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        assertTrue(servico.concluir(dono, existente.getId(), true).concluida());
        assertFalse(servico.concluir(dono, existente.getId(), false).concluida());
    }

    @Test
    void excluir_doDono_removeATarefa() {
        Tarefa existente = new Tarefa(dono, objetivoId, "Tarefa", null);
        when(tarefas.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        servico.excluir(dono, existente.getId());

        verify(tarefas).delete(existente);
    }

    // ---------- isolamento entre usuários ----------

    @Test
    void atualizar_tarefaDeOutroUsuario_retorna404() {
        UUID idAlheio = UUID.randomUUID();
        when(tarefas.findByIdAndUsuarioId(idAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.atualizar(intruso, idAlheio, new TarefaRequest("Invadida", 1)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(tarefas, never()).findById(any());
    }

    @Test
    void concluir_tarefaDeOutroUsuario_retorna404() {
        UUID idAlheio = UUID.randomUUID();
        when(tarefas.findByIdAndUsuarioId(idAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class, () -> servico.concluir(intruso, idAlheio, true));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
    }

    @Test
    void excluir_tarefaDeOutroUsuario_retorna404ENaoApagaNada() {
        UUID idAlheio = UUID.randomUUID();
        when(tarefas.findByIdAndUsuarioId(idAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class, () -> servico.excluir(intruso, idAlheio));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(tarefas, never()).delete(any());
        verify(tarefas, never()).deleteById(any());
    }

    // ---------- plano de 7 dias ----------

    @Test
    void plano_semTarefas_trazOsSeteDiasVazios() {
        objetivoExisteParaODono();
        when(tarefas.findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(objetivoId, dono)).thenReturn(List.of());

        PlanoResponse plano = servico.plano(dono, objetivoId);

        assertEquals(objetivoId, plano.objetivoId());
        assertEquals(0, plano.total());
        assertEquals(0, plano.concluidas());
        assertEquals(7, plano.dias().size());
        assertTrue(plano.dias().stream().allMatch(d -> d.tarefas().isEmpty()));
        assertTrue(plano.semDia().isEmpty());
    }

    @Test
    void plano_agrupaPorDiaSeparaSemDiaEContaProgresso() {
        objetivoExisteParaODono();
        Tarefa a = new Tarefa(dono, objetivoId, "A", 1);
        Tarefa b = new Tarefa(dono, objetivoId, "B", 1);
        Tarefa c = new Tarefa(dono, objetivoId, "C", 7);
        Tarefa solta = new Tarefa(dono, objetivoId, "Solta", null);
        a.definirConclusao(true);
        solta.definirConclusao(true);
        when(tarefas.findAllByObjetivoIdAndUsuarioIdOrderByCriadoEmAsc(objetivoId, dono))
                .thenReturn(List.of(a, b, c, solta));

        PlanoResponse plano = servico.plano(dono, objetivoId);

        assertEquals(4, plano.total());
        assertEquals(2, plano.concluidas());
        assertEquals(List.of(1, 2, 3, 4, 5, 6, 7), plano.dias().stream().map(PlanoResponse.DiaDoPlano::dia).toList());
        assertEquals(List.of("A", "B"), plano.dias().get(0).tarefas().stream().map(TarefaResponse::titulo).toList());
        assertTrue(plano.dias().get(1).tarefas().isEmpty());
        assertEquals(List.of("C"), plano.dias().get(6).tarefas().stream().map(TarefaResponse::titulo).toList());
        assertEquals(List.of("Solta"), plano.semDia().stream().map(TarefaResponse::titulo).toList());
    }

    @Test
    void plano_objetivoDeOutroUsuario_retorna404() {
        when(objetivos.findByIdAndUsuarioId(objetivoId, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class, () -> servico.plano(intruso, objetivoId));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
    }
}
