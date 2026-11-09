package br.com.norte.objetivos;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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

@WebMvcTest(controllers = ObjetivoController.class)
@Import({SecurityConfig.class, JwtConfig.class, TokenService.class})
@TestPropertySource(properties = {
        "norte.security.jwt.secret=segredo-de-teste-com-pelo-menos-32-bytes-ok!",
        "norte.security.jwt.access-token-ttl=15m",
        "norte.security.jwt.refresh-token-ttl=30d",
        "norte.cors.allowed-origin-patterns=http://localhost:*"
})
class ObjetivoControllerTest {

    private static final String BASE = "/api/v1/objetivos";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @MockitoBean
    private ObjetivoService objetivoService;

    private String bearer(UUID usuarioId) {
        return "Bearer " + tokenService.emitir(usuarioId, "refresh-qualquer").accessToken();
    }

    private static ObjetivoResponse resposta(UUID id, String titulo, boolean concluido) {
        Instant agora = Instant.parse("2026-11-09T12:00:00Z");
        return new ObjetivoResponse(id, titulo, null, concluido, agora, agora);
    }

    // ---------- autenticação ----------

    @Test
    void todasAsRotas_semToken_retornam401() throws Exception {
        UUID id = UUID.randomUUID();
        String json = "{\"titulo\":\"Meta\"}";

        mockMvc.perform(get(BASE)).andExpect(status().isUnauthorized());
        mockMvc.perform(post(BASE).contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(put(BASE + "/" + id).contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(patch(BASE + "/" + id + "/conclusao")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"concluido\":true}"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(delete(BASE + "/" + id)).andExpect(status().isUnauthorized());

        verifyNoInteractions(objetivoService);
    }

    // ---------- leitura e criação ----------

    @Test
    void listar_usaOUsuarioDoToken() throws Exception {
        UUID usuario = UUID.randomUUID();
        when(objetivoService.listar(usuario)).thenReturn(List.of(resposta(UUID.randomUUID(), "Meta", false)));

        mockMvc.perform(get(BASE).header("Authorization", bearer(usuario)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].titulo").value("Meta"))
                .andExpect(jsonPath("$[0].concluido").value(false));

        verify(objetivoService).listar(usuario);
    }

    @Test
    void criar_valido_retorna201SemExporODono() throws Exception {
        UUID usuario = UUID.randomUUID();
        when(objetivoService.criar(eq(usuario), any(ObjetivoRequest.class)))
                .thenReturn(resposta(UUID.randomUUID(), "Aprender Java", false));

        mockMvc.perform(post(BASE)
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Aprender Java\",\"descricao\":\"todo dia\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.titulo").value("Aprender Java"))
                .andExpect(jsonPath("$.usuarioId").doesNotExist());
    }

    @Test
    void criar_ignoraUsuarioIdEnviadoNoCorpo() throws Exception {
        UUID usuarioDoToken = UUID.randomUUID();
        UUID usuarioDoCorpo = UUID.randomUUID();
        when(objetivoService.criar(eq(usuarioDoToken), any(ObjetivoRequest.class)))
                .thenReturn(resposta(UUID.randomUUID(), "Meta", false));

        mockMvc.perform(post(BASE)
                        .header("Authorization", bearer(usuarioDoToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Meta\",\"usuarioId\":\"" + usuarioDoCorpo + "\"}"))
                .andExpect(status().isCreated());

        verify(objetivoService).criar(eq(usuarioDoToken), any(ObjetivoRequest.class));
    }

    // ---------- validação ----------

    @Test
    void criar_tituloEmBranco_retorna400ComDetalhe() throws Exception {
        mockMvc.perform(post(BASE)
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"   \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.titulo").exists());

        verifyNoInteractions(objetivoService);
    }

    @Test
    void criar_tituloMuitoLongo_retorna400() throws Exception {
        String titulo = "a".repeat(121);

        mockMvc.perform(post(BASE)
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"" + titulo + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.titulo").exists());

        verifyNoInteractions(objetivoService);
    }

    @Test
    void criar_descricaoMuitoLonga_retorna400() throws Exception {
        String descricao = "a".repeat(501);

        mockMvc.perform(post(BASE)
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Meta\",\"descricao\":\"" + descricao + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.descricao").exists());

        verifyNoInteractions(objetivoService);
    }

    @Test
    void concluir_semCampoConcluido_retorna400() throws Exception {
        mockMvc.perform(patch(BASE + "/" + UUID.randomUUID() + "/conclusao")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.concluido").exists());

        verifyNoInteractions(objetivoService);
    }

    // ---------- alteração, exclusão e objetivo de outra pessoa ----------

    @Test
    void concluir_valido_retorna200() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        when(objetivoService.concluir(usuario, id, true)).thenReturn(resposta(id, "Meta", true));

        mockMvc.perform(patch(BASE + "/" + id + "/conclusao")
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"concluido\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.concluido").value(true));
    }

    @Test
    void excluir_valido_retorna204() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();

        mockMvc.perform(delete(BASE + "/" + id).header("Authorization", bearer(usuario)))
                .andExpect(status().isNoContent());

        verify(objetivoService).excluir(usuario, id);
    }

    @Test
    void atualizar_objetivoNaoEncontrado_retorna404NoFormatoPadrao() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        when(objetivoService.atualizar(eq(usuario), eq(id), any(ObjetivoRequest.class)))
                .thenThrow(ApiException.naoEncontrado("Objetivo não encontrado."));

        mockMvc.perform(put(BASE + "/" + id)
                        .header("Authorization", bearer(usuario))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titulo\":\"Meta\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Objetivo não encontrado."));
    }

    @Test
    void excluir_objetivoNaoEncontrado_retorna404NoFormatoPadrao() throws Exception {
        UUID usuario = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        org.mockito.Mockito.doThrow(ApiException.naoEncontrado("Objetivo não encontrado."))
                .when(objetivoService).excluir(usuario, id);

        mockMvc.perform(delete(BASE + "/" + id).header("Authorization", bearer(usuario)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Objetivo não encontrado."));
    }
}
