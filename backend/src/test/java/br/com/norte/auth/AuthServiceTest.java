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
import java.util.Optional;
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

    @Mock
    private UsuarioRepository usuarios;

    @Mock
    private TokenService tokens;

    // Custo baixo só para os testes ficarem rápidos; em produção o custo é 12.
    private final PasswordEncoder encoder = new BCryptPasswordEncoder(4);

    private AuthService service;

    @BeforeEach
    void preparar() {
        service = new AuthService(usuarios, encoder, tokens);
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
    void login_credenciaisCorretas_emiteToken() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));
        TokenResponse esperado = new TokenResponse("token-de-teste", "Bearer", 900);
        when(tokens.emitir(ana.getId())).thenReturn(esperado);

        TokenResponse resp = service.login(new LoginRequest("Ana@Exemplo.com", "senhaforte123"));

        assertEquals("token-de-teste", resp.accessToken());
    }

    @Test
    void login_senhaErrada_retornaNaoAutorizado() {
        Usuario ana = new Usuario("ana@exemplo.com", encoder.encode("senhaforte123"), "Ana");
        when(usuarios.findByEmail("ana@exemplo.com")).thenReturn(Optional.of(ana));

        ApiException e = assertThrows(ApiException.class,
                () -> service.login(new LoginRequest("ana@exemplo.com", "outra-senha-qualquer")));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verifyNoInteractions(tokens);
    }

    @Test
    void login_emailInexistente_retornaMesmaMensagemDeSenhaErrada() {
        when(usuarios.findByEmail("ninguem@exemplo.com")).thenReturn(Optional.empty());

        ApiException e = assertThrows(ApiException.class,
                () -> service.login(new LoginRequest("ninguem@exemplo.com", "senhaforte123")));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        assertEquals("E-mail ou senha inválidos.", e.getMessage());
        verifyNoInteractions(tokens);
    }
}
