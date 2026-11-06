package br.com.norte.auth;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.com.norte.auth.dto.TokenResponse;
import br.com.norte.auth.dto.UsuarioResponse;
import br.com.norte.shared.error.ApiException;
import br.com.norte.shared.status.StatusController;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = {AuthController.class, PerfilController.class, StatusController.class})
@Import({SecurityConfig.class, JwtConfig.class, TokenService.class})
@TestPropertySource(properties = {
        "norte.security.jwt.secret=segredo-de-teste-com-pelo-menos-32-bytes-ok!",
        "norte.security.jwt.access-token-ttl=15m"
})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @MockitoBean
    private AuthService authService;

    @Test
    void registro_valido_retorna201SemExporSenha() throws Exception {
        UUID id = UUID.randomUUID();
        when(authService.registrar(any())).thenReturn(new UsuarioResponse(id, "ana@exemplo.com", "Ana"));

        mockMvc.perform(post("/api/v1/auth/registro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"senhaforte123\",\"nomeExibicao\":\"Ana\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value("ana@exemplo.com"))
                .andExpect(jsonPath("$.senha").doesNotExist())
                .andExpect(jsonPath("$.senhaHash").doesNotExist());
    }

    @Test
    void registro_senhaCurta_retorna400ComDetalhe() throws Exception {
        mockMvc.perform(post("/api/v1/auth/registro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.senha").exists());
    }

    @Test
    void registro_emailInvalido_retorna400() throws Exception {
        mockMvc.perform(post("/api/v1/auth/registro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"isso-nao-e-email\",\"senha\":\"senhaforte123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.email").exists());
    }

    @Test
    void login_valido_retornaToken() throws Exception {
        when(authService.login(any())).thenReturn(new TokenResponse("abc", "Bearer", 900));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"senhaforte123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("abc"))
                .andExpect(jsonPath("$.tipo").value("Bearer"));
    }

    @Test
    void login_credenciaisInvalidas_retorna401() throws Exception {
        when(authService.login(any())).thenThrow(ApiException.naoAutorizado("E-mail ou senha inválidos."));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"errada\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void me_semToken_retorna401() throws Exception {
        mockMvc.perform(get("/api/v1/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void me_comTokenValido_retornaOPerfilDoDonoDoToken() throws Exception {
        UUID id = UUID.randomUUID();
        when(authService.perfil(id)).thenReturn(new UsuarioResponse(id, "ana@exemplo.com", "Ana"));
        String token = tokenService.emitir(id).accessToken();

        mockMvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.email").value("ana@exemplo.com"));
    }

    @Test
    void me_comTokenAdulterado_retorna401() throws Exception {
        String token = tokenService.emitir(UUID.randomUUID()).accessToken();
        String adulterado = token.substring(0, token.length() - 3) + "abc";

        mockMvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + adulterado))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void status_continuaPublico() throws Exception {
        mockMvc.perform(get("/api/v1/status")).andExpect(status().isOk());
    }
}
