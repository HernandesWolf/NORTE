package br.com.norte.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import br.com.norte.auth.dto.LoginRequest;
import br.com.norte.auth.dto.RegistroRequest;
import br.com.norte.auth.dto.TokenResponse;
import br.com.norte.auth.dto.UsuarioResponse;
import br.com.norte.shared.error.ApiException;
import br.com.norte.usuarios.Usuario;
import br.com.norte.usuarios.UsuarioRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    private static final String IP = "203.0.113.7";

    @Mock
    private UsuarioRepository usuarios;

    @Mock
    private TokenService tokens;

    @Mock
    private RefreshTokenService refreshTokens;

    // Custo baixo só para os testes ficarem rápidos; em produção o custo é 12.
    private final PasswordEncoder encoder = new BCryptPasswordEncoder(4);

    private final Clock relogio = Clock.fixed(Instant.parse("2026-11-07T12:00:00Z"), ZoneOffset.UTC);

    private AuthService service;

    @BeforeEach
    void preparar() {
        service = new AuthService(usuarios, encoder, tokens, refreshTokens, new LimitadorDeLogin(relogio));
    }

    @Test
    void registrar_normalizaEmailEGuardaApenasOHash() {
        when(usuarios.existsByEmail("ana@exemplo.com")).thenReturn(false);
        when(usuarios.saveAndFlush(any(Usuario.class))).thenAnswer(i -> i.getArgument(0));

        UsuarioResponse resp = service.registrar(new RegistroRequest("  Ana@Exemplo.com ", "senhaforte123", " Ana "));

        ArgumentCaptor<Usuario> captor = ArgumentCaptor.forClass(Usuario.class);
        verify(usuarios).saveAndFlush(captor.capture());
        Usuario salvo = captor.getValue();
        assertEquals("ana@exemplo.com", salvo.getEmail());
        assertEquals("Ana", salvo.getNomeExibicao());
        assertNotEquals("senhaforte123", salvo.getSenhaHash());
        assertTrue(encoder.matches("senhaforte123", salvo.getSenhaHash()));
        assertEquals("ana@exemplo.com", resp.email());
    }

    @Test
    void registrar_emailDuplicado_retornaConflito() {
        when(usuarios.existsByEmail("ana@exemplo.com")).thenReturn(true);

        ApiException e = assertThrows(ApiException.class,
                () -> service.registrar(new RegistroRequest("ana@exemplo.com", "senhaforte123", null)));

        assertEquals(HttpStatus.CONFLICT, e.getStatus());
        verify(usuarios, never()).saveAndFlush(any());
    }

    @Test
    void registrar_senhaMaiorQue72Bytes_retornaRequisicaoInvalida() {
        // 40 caracteres de 2 bytes cada = 80 bytes
        String senhaLonga = "ç".repeat(40);

        ApiException e = assertThrows(ApiException.class,
                () -> service.registrar(new RegistroRequest("ana@exemplo.com", senhaLonga, null)));

        assertEquals(HttpStatus.BAD_REQUEST, e.getStatus());
        verifyNoInteractions(usuarios);
    }

    @Test
    void login_credenciaisCorretas_criaSessaoEEmiteTokens() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));
        when(refreshTokens.criar(ana.getId())).thenReturn("refresh-bruto");
        TokenResponse esperado = new TokenResponse("token-de-teste", "refresh-bruto", "Bearer", 900);
        when(tokens.emitir(ana.getId(), "refresh-bruto")).thenReturn(esperado);

        TokenResponse resp = service.login(new LoginRequest("Ana@Exemplo.com", "senhaforte123"), IP);

        assertEquals("token-de-teste", resp.accessToken());
        assertEquals("refresh-bruto", resp.refreshToken());
    }

    @Test
    void login_senhaErrada_retornaNaoAutorizado() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));

        ApiException e = assertThrows(ApiException.class,
                () -> service.login(new LoginRequest("ana@exemplo.com", "outra-senha-qualquer"), IP));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verifyNoInteractions(tokens);
        verifyNoInteractions(refreshTokens);
    }

    @Test
    void login_emailInexistente_retornaMesmaMensagemDeSenhaErrada() {
        when(usuarios.findByEmail("ninguem@exemplo.com")).thenReturn(Optional.empty());

        ApiException e = assertThrows(ApiException.class,
                () -> service.login(new LoginRequest("ninguem@exemplo.com", "senhaforte123"), IP));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        assertEquals("E-mail ou senha inválidos.", e.getMessage());
        verifyNoInteractions(tokens);
        verifyNoInteractions(refreshTokens);
    }

    @Test
    void login_apos5Falhas_bloqueiaMesmoComSenhaCorreta() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));

        for (int i = 0; i < LimitadorDeLogin.MAX_FALHAS; i++) {
            assertThrows(ApiException.class,
                    () -> service.login(new LoginRequest("ana@exemplo.com", "senha-errada-123"), IP));
        }

        ApiException bloqueio = assertThrows(ApiException.class,
                () -> service.login(new LoginRequest("ana@exemplo.com", "senhaforte123"), IP));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, bloqueio.getStatus());
        assertTrue(bloqueio.getRetryAfterSegundos() > 0);
        verifyNoInteractions(tokens);
    }

    @Test
    void login_bloqueioDeUmIp_naoAfetaOutroIp() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));
        when(refreshTokens.criar(ana.getId())).thenReturn("refresh-bruto");
        when(tokens.emitir(ana.getId(), "refresh-bruto"))
                .thenReturn(new TokenResponse("tok", "refresh-bruto", "Bearer", 900));

        for (int i = 0; i < LimitadorDeLogin.MAX_FALHAS; i++) {
            assertThrows(ApiException.class,
                    () -> service.login(new LoginRequest("ana@exemplo.com", "senha-errada-123"), "198.51.100.1"));
        }

        // Quem tentou de outro IP (a dona da conta, por exemplo) continua conseguindo entrar.
        TokenResponse resp = service.login(new LoginRequest("ana@exemplo.com", "senhaforte123"), IP);
        assertEquals("tok", resp.accessToken());
    }

    @Test
    void login_sucessoZeraAContagemDeFalhas() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));
        when(refreshTokens.criar(ana.getId())).thenReturn("refresh-bruto");
        when(tokens.emitir(ana.getId(), "refresh-bruto"))
                .thenReturn(new TokenResponse("tok", "refresh-bruto", "Bearer", 900));

        for (int i = 0; i < LimitadorDeLogin.MAX_FALHAS - 1; i++) {
            assertThrows(ApiException.class,
                    () -> service.login(new LoginRequest("ana@exemplo.com", "senha-errada-123"), IP));
        }
        service.login(new LoginRequest("ana@exemplo.com", "senhaforte123"), IP);

        // Se o sucesso NÃO zerasse a contagem, já haveria 4 falhas e o 2º erro abaixo viraria 429.
        // Com a contagem zerada, os MAX_FALHAS erros seguintes ainda são "senha errada" (401).
        for (int i = 0; i < LimitadorDeLogin.MAX_FALHAS; i++) {
            ApiException e = assertThrows(ApiException.class,
                    () -> service.login(new LoginRequest("ana@exemplo.com", "senha-errada-123"), IP));
            assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        }
    }

    @Test
    void renovar_trocaOTokenEEmiteNovoPar() {
        UUID usuarioId = UUID.randomUUID();
        when(refreshTokens.rotacionar("refresh-antigo"))
                .thenReturn(new RefreshTokenService.Rotacao(usuarioId, "refresh-novo"));
        TokenResponse esperado = new TokenResponse("acesso-novo", "refresh-novo", "Bearer", 900);
        when(tokens.emitir(usuarioId, "refresh-novo")).thenReturn(esperado);

        TokenResponse resp = service.renovar("refresh-antigo");

        assertEquals("acesso-novo", resp.accessToken());
        assertEquals("refresh-novo", resp.refreshToken());
    }

    @Test
    void sair_revogaOTokenApresentado() {
        service.sair("refresh-123");

        verify(refreshTokens).revogar("refresh-123");
    }
}
