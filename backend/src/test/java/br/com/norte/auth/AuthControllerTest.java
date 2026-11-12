package br.com.norte.auth;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
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
        "norte.security.jwt.access-token-ttl=15m",
        "norte.security.jwt.refresh-token-ttl=30d",
        "norte.cors.allowed-origin-patterns=http://localhost:*"
})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private LimitadorDeCadastro limitadorDeCadastro;

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

        // O MockMvc simula o cliente em 127.0.0.1: é essa chave que o limitador deve receber.
        verify(limitadorDeCadastro).registrar("127.0.0.1");
    }

    @Test
    void registro_comMuitosCadastrosDoMesmoIp_retorna429ComRetryAfterSemChamarOService() throws Exception {
        doThrow(ApiException.muitasTentativas("Muitos cadastros.", 600)).when(limitadorDeCadastro).registrar(any());

        mockMvc.perform(post("/api/v1/auth/registro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"senhaforte123\"}"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "600"));

        verifyNoInteractions(authService);
    }

    @Test
    void registro_senhaCurta_retorna400ComDetalhe() throws Exception {
        mockMvc.perform(post("/api/v1/auth/registro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.senha").exists());

        // Pedido inválido é barrado antes de custar BCrypt: não gasta o limite do IP.
        verifyNoInteractions(limitadorDeCadastro);
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
    void login_valido_retornaAccessEREfreshToken() throws Exception {
        when(authService.login(any(), any())).thenReturn(new TokenResponse("abc", "refresh-123", "Bearer", 900));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"senhaforte123\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("abc"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-123"))
                .andExpect(jsonPath("$.tipo").value("Bearer"));
    }

    @Test
    void login_credenciaisInvalidas_retorna401() throws Exception {
        when(authService.login(any(), any())).thenThrow(ApiException.naoAutorizado("E-mail ou senha inválidos."));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"errada\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void login_comMuitasTentativas_retorna429ComRetryAfter() throws Exception {
        when(authService.login(any(), any())).thenThrow(ApiException.muitasTentativas("Aguarde.", 120));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"ana@exemplo.com\",\"senha\":\"errada\"}"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "120"));
    }

    @Test
    void refresh_valido_retornaNovoParDeTokens() throws Exception {
        when(authService.renovar("refresh-antigo")).thenReturn(new TokenResponse("novo", "refresh-novo", "Bearer", 900));

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"refresh-antigo\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").value("novo"))
                .andExpect(jsonPath("$.refreshToken").value("refresh-novo"));
    }

    @Test
    void refresh_invalido_retorna401() throws Exception {
        when(authService.renovar("lixo")).thenThrow(ApiException.naoAutorizado("Sessão inválida ou expirada."));

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"lixo\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void refresh_semToken_retorna400() throws Exception {
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"  \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.refreshToken").exists());
    }

    @Test
    void logout_retorna204EEncerraASessao() throws Exception {
        mockMvc.perform(post("/api/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"refresh-123\"}"))
                .andExpect(status().isNoContent());

        verify(authService).sair("refresh-123");
    }

    @Test
    void me_semToken_retorna401() throws Exception {
        mockMvc.perform(get("/api/v1/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void me_comTokenValido_retornaOPerfilDoDonoDoToken() throws Exception {
        UUID id = UUID.randomUUID();
        when(authService.perfil(id)).thenReturn(new UsuarioResponse(id, "ana@exemplo.com", "Ana"));
        String token = tokenService.emitir(id, "refresh-qualquer").accessToken();

        mockMvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.email").value("ana@exemplo.com"));
    }

    @Test
    void me_comTokenAdulterado_retorna401() throws Exception {
        String token = tokenService.emitir(UUID.randomUUID(), "refresh-qualquer").accessToken();
        String adulterado = token.substring(0, token.length() - 3) + "abc";

        mockMvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + adulterado))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void status_continuaPublico() throws Exception {
        mockMvc.perform(get("/api/v1/status")).andExpect(status().isOk());
    }

    @Test
    void cors_preVoo_deOrigemPermitida_ehAceito() throws Exception {
        mockMvc.perform(options("/api/v1/auth/login")
                        .header("Origin", "http://localhost:54321")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:54321"));
    }

    @Test
    void cors_preVoo_deOrigemDesconhecida_ehRecusado() throws Exception {
        mockMvc.perform(options("/api/v1/auth/login")
                        .header("Origin", "http://site-desconhecido.exemplo")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isForbidden());
    }
}
