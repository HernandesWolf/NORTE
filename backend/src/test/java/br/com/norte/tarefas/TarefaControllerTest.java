package br.com.norte.tarefas;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.com.norte.auth.JwtConfig;
import br.com.norte.auth.SecurityConfig;
import br.com.norte.auth.TokenService;
import br.com.norte.shared.error.ApiException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = TarefaController.class)
@Import({SecurityConfig.class, JwtConfig.class, TokenService.class})
@TestPropertySource(properties = {
        "norte.security.jwt.secret=segredo-de-teste-com-pelo-menos-32-bytes-ok!",
        "norte.security.jwt.access-token-ttl=15m",
        "norte.security.jwt.refresh-token-ttl=30d",
        "norte.cors.allowed-origin-patterns=http://localhost:*"
})
class TarefaControllerTest {

    private static final String API = "/api/v1";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @MockitoBean
    private TarefaService tarefaService;

    private String bearer(UUID usuarioId) {
        return "Bearer " + tokenService.emitir(usuarioId, "refresh-qualquer").accessToken();
    }

    private static TarefaResponse resposta(UUID objetivoId, String titulo, Integer dia, boolean concluida) {
        Instant agora = Instant.parse("2026-11-10T12:00:00Z");
        return new TarefaResponse(UUID.randomUUID(), objetivoId, titulo, dia, concluida, agora, agora);
    }

    // ---------- autenticação ----------

    @Test
    void todasAsRotas_semToken_retornam401() throws Exception {
        UUID objetivo = UUID.randomUUID();
        UUID tarefa = UUID.randomUUID();
        String json = "{\"titulo\":\"Tarefa\"}";

        mockMvc.perform(get(API + "/objetivos/" + objetivo + "/tarefas")).andExpect(status().isUnauthorized());
        mockMvc.perform(post(API + "/objetivos/" + objetivo + "/tarefas")
                        .contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get(API + "/objetivos/" + objetivo + "/plano")).andExpect(status().isUnauthorized());
        mockMvc.perform(put(API + "/tarefas/" + tarefa).contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(patch(API + "/tarefas/" + tarefa + "/conclusao")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"concluida\":true}"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(delete(API + "/tarefas/" + tarefa)).andExpect(status().isUnauthorized());

        verifyNoInteractions(tarefaService);
    }

    // ---------- leitura e criação ----------

    @Test
    void listar_usaOUsuarioDoToken() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID objetivo = UUID.randomUUID();
        when(tarefaService.listar(usuario, objetivo)).thenReturn(List.of(resposta(objetivo, "Estudar", 2, false)));

        mockMvc.perform(get(API + "/objetivos/" + objetivo + "/tarefas").header("Authorization", bearer(usuario)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].titulo").value("Estudar"))
                .andExpect(jsonPath("$[0].dia").value(2));

        verify(tarefaService).listar(usuario, objetivo);
    }

    @Test
    void criar_valido_retorna201SemExporODono() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID objetivo = UUID.randomUUID();
        when(tarefaService.criar(eq(usuario), eq(objetivo), any(TarefaRequest.class)))
                .thenReturn(resposta(objetivo, "Estudar", 1, false));

        mockMvc.perform(post(API + "/objetivos/" + objetivo + "/tarefas")
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Estudar\",\"dia\":1}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.titulo").value("Estudar"))
                .andExpect(jsonPath("$.usuarioId").doesNotExist());
    }

    @Test
    void criar_ignoraUsuarioIdEnviadoNoCorpo() throws Exception {
        UUID usuarioDoToken = UUID.randomUUID();
        UUID objetivo = UUID.randomUUID();
        when(tarefaService.criar(eq(usuarioDoToken), eq(objetivo), any(TarefaRequest.class)))
                .thenReturn(resposta(objetivo, "Tarefa", null, false));

        mockMvc.perform(post(API + "/objetivos/" + objetivo + "/tarefas")
                        .header("Authorization", bearer(usuarioDoToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Tarefa\",\"usuarioId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isCreated());

        verify(tarefaService).criar(eq(usuarioDoToken), eq(objetivo), any(TarefaRequest.class));
    }

    // ---------- validação ----------

    @Test
    void criar_tituloEmBranco_retorna400ComDetalhe() throws Exception {
        mockMvc.perform(post(API + "/objetivos/" + UUID.randomUUID() + "/tarefas")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"   \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.titulo").exists());

        verifyNoInteractions(tarefaService);
    }

    @Test
    void criar_tituloMuitoLongo_retorna400() throws Exception {
        mockMvc.perform(post(API + "/objetivos/" + UUID.randomUUID() + "/tarefas")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"" + "a".repeat(121) + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.titulo").exists());

        verifyNoInteractions(tarefaService);
    }

    @Test
    void criar_diaForaDoPlano_retorna400() throws Exception {
        for (int diaInvalido : new int[] {0, 8, -1}) {
            mockMvc.perform(post(API + "/objetivos/" + UUID.randomUUID() + "/tarefas")
                            .header("Authorization", bearer(UUID.randomUUID()))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"titulo\":\"Tarefa\",\"dia\":" + diaInvalido + "}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.erros.dia").exists());
        }

        verifyNoInteractions(tarefaService);
    }

    @Test
    void concluir_semCampoConcluida_retorna400() throws Exception {
        mockMvc.perform(patch(API + "/tarefas/" + UUID.randomUUID() + "/conclusao")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.concluida").exists());

        verifyNoInteractions(tarefaService);
    }

    // ---------- plano ----------

    @Test
    void plano_retornaOsDiasEOProgresso() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID objetivo = UUID.randomUUID();
        TarefaResponse t = resposta(objetivo, "Estudar", 1, true);
        PlanoResponse plano = new PlanoResponse(objetivo, 1, 1,
                List.of(new PlanoResponse.DiaDoPlano(1, List.of(t))), List.of());
        when(tarefaService.plano(usuario, objetivo)).thenReturn(plano);

        mockMvc.perform(get(API + "/objetivos/" + objetivo + "/plano").header("Authorization", bearer(usuario)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(1))
                .andExpect(jsonPath("$.concluidas").value(1))
                .andExpect(jsonPath("$.dias[0].dia").value(1))
                .andExpect(jsonPath("$.dias[0].tarefas[0].titulo").value("Estudar"))
                .andExpect(jsonPath("$.semDia").isEmpty());
    }

    // ---------- alteração, exclusão e itens de outra pessoa ----------

    @Test
    void concluir_valido_retorna200() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        when(tarefaService.concluir(usuario, id, true))
                .thenReturn(resposta(UUID.randomUUID(), "Tarefa", 1, true));

        mockMvc.perform(patch(API + "/tarefas/" + id + "/conclusao")
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"concluida\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.concluida").value(true));
    }

    @Test
    void excluir_valido_retorna204() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();

        mockMvc.perform(delete(API + "/tarefas/" + id).header("Authorization", bearer(usuario)))
                .andExpect(status().isNoContent());

        verify(tarefaService).excluir(usuario, id);
    }

    @Test
    void atualizar_tarefaNaoEncontrada_retorna404NoFormatoPadrao() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        when(tarefaService.atualizar(eq(usuario), eq(id), any(TarefaRequest.class)))
                .thenThrow(ApiException.naoEncontrado("Tarefa não encontrada."));

        mockMvc.perform(put(API + "/tarefas/" + id)
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Tarefa\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Tarefa não encontrada."));
    }

    @Test
    void excluir_tarefaNaoEncontrada_retorna404NoFormatoPadrao() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        doThrow(ApiException.naoEncontrado("Tarefa não encontrada.")).when(tarefaService).excluir(usuario, id);

        mockMvc.perform(delete(API + "/tarefas/" + id).header("Authorization", bearer(usuario)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Tarefa não encontrada."));
    }

    @Test
    void criar_limiteDeTarefasAtingido_retorna409() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID objetivo = UUID.randomUUID();
        when(tarefaService.criar(eq(usuario), eq(objetivo), any(TarefaRequest.class)))
                .thenThrow(ApiException.conflito("Este objetivo já tem 50 tarefas."));

        mockMvc.perform(post(API + "/objetivos/" + objetivo + "/tarefas")
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Mais uma\"}"))
                .andExpect(status().isConflict());
    }
}
