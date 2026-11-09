package br.com.norte.objetivos;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;

@ExtendWith(MockitoExtension.class)
class ObjetivoServiceTest {

    @Mock
    private ObjetivoRepository repositorio;

    @InjectMocks
    private ObjetivoService servico;

    private final UUID dono = UUID.randomUUID();
    private final UUID intruso = UUID.randomUUID();

    // ---------- criar / listar ----------

    @Test
    void criar_limpaEspacosEGravaParaODonoDoToken() {
        when(repositorio.saveAndFlush(any(Objetivo.class))).thenAnswer(i -> i.getArgument(0));

        ObjetivoResponse resposta = servico.criar(dono, new ObjetivoRequest("  Aprender Java  ", "  base sólida  "));

        assertEquals("Aprender Java", resposta.titulo());
        assertEquals("base sólida", resposta.descricao());
        assertFalse(resposta.concluido());
        org.mockito.ArgumentCaptor<Objetivo> capturado = org.mockito.ArgumentCaptor.forClass(Objetivo.class);
        verify(repositorio).saveAndFlush(capturado.capture());
        assertEquals(dono, capturado.getValue().getUsuarioId());
    }

    @Test
    void criar_descricaoEmBrancoViraNula() {
        when(repositorio.saveAndFlush(any(Objetivo.class))).thenAnswer(i -> i.getArgument(0));

        ObjetivoResponse resposta = servico.criar(dono, new ObjetivoRequest("Meta", "   "));

        assertNull(resposta.descricao());
    }

    @Test
    void criar_usuarioQueNaoExisteMais_retorna401() {
        when(repositorio.saveAndFlush(any(Objetivo.class))).thenThrow(new DataIntegrityViolationException("fk"));

        ApiException erro = assertThrows(
                ApiException.class, () -> servico.criar(dono, new ObjetivoRequest("Meta", null)));

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatus());
    }

    @Test
    void listar_consultaSomenteOsObjetivosDoUsuarioInformado() {
        Objetivo meu = new Objetivo(dono, "Meu", null);
        when(repositorio.findAllByUsuarioIdOrderByCriadoEmDesc(dono)).thenReturn(List.of(meu));

        List<ObjetivoResponse> lista = servico.listar(dono);

        assertEquals(1, lista.size());
        assertEquals("Meu", lista.get(0).titulo());
        verify(repositorio, never()).findAll();
    }

    // ---------- operações do dono ----------

    @Test
    void atualizar_doDono_alteraTituloEDescricao() {
        Objetivo existente = new Objetivo(dono, "Antigo", "velha");
        when(repositorio.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        ObjetivoResponse resposta =
                servico.atualizar(dono, existente.getId(), new ObjetivoRequest(" Novo ", null));

        assertEquals("Novo", resposta.titulo());
        assertNull(resposta.descricao());
    }

    @Test
    void concluir_doDono_marcaEDesmarca() {
        Objetivo existente = new Objetivo(dono, "Meta", null);
        when(repositorio.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        assertTrue(servico.concluir(dono, existente.getId(), true).concluido());
        assertFalse(servico.concluir(dono, existente.getId(), false).concluido());
    }

    @Test
    void excluir_doDono_removeOObjetivo() {
        Objetivo existente = new Objetivo(dono, "Meta", null);
        when(repositorio.findByIdAndUsuarioId(existente.getId(), dono)).thenReturn(Optional.of(existente));

        servico.excluir(dono, existente.getId());

        verify(repositorio).delete(existente);
    }

    // ---------- isolamento entre usuários ----------
    // O objetivo existe, mas é do "dono". Para o "intruso" a busca filtrada por usuário não acha nada:
    // a resposta tem que ser 404 (igual a "não existe"), e nada pode ser alterado.

    @Test
    void atualizar_objetivoDeOutroUsuario_retorna404() {
        UUID idDoObjetivoAlheio = UUID.randomUUID();
        when(repositorio.findByIdAndUsuarioId(idDoObjetivoAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.atualizar(intruso, idDoObjetivoAlheio, new ObjetivoRequest("Invadido", null)));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(repositorio, never()).findById(any());
    }

    @Test
    void concluir_objetivoDeOutroUsuario_retorna404() {
        UUID idDoObjetivoAlheio = UUID.randomUUID();
        when(repositorio.findByIdAndUsuarioId(idDoObjetivoAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.concluir(intruso, idDoObjetivoAlheio, true));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(repositorio, never()).findById(any());
    }

    @Test
    void excluir_objetivoDeOutroUsuario_retorna404ENaoApagaNada() {
        UUID idDoObjetivoAlheio = UUID.randomUUID();
        when(repositorio.findByIdAndUsuarioId(idDoObjetivoAlheio, intruso)).thenReturn(Optional.empty());

        ApiException erro = assertThrows(ApiException.class,
                () -> servico.excluir(intruso, idDoObjetivoAlheio));

        assertEquals(HttpStatus.NOT_FOUND, erro.getStatus());
        verify(repositorio, never()).delete(any());
        verify(repositorio, never()).deleteById(any());
    }
}
