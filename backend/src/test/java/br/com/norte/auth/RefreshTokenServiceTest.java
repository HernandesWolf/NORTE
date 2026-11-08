package br.com.norte.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Duration;
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
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    private static final Instant AGORA = Instant.parse("2026-11-07T12:00:00Z");

    @Mock
    private RefreshTokenRepository repositorio;

    private RefreshTokenService service;

    private final UUID usuarioId = UUID.randomUUID();

    @BeforeEach
    void preparar() {
        JwtProperties props = new JwtProperties("segredo-de-teste-com-pelo-menos-32-bytes-ok!",
                Duration.ofMinutes(15), Duration.ofDays(30));
        service = new RefreshTokenService(repositorio, props, Clock.fixed(AGORA, ZoneOffset.UTC));
    }

    /** Cria um registro como o banco o teria, para um valor bruto conhecido. */
    private RefreshToken registro(String bruto, Instant expiraEm) {
        return new RefreshToken(usuarioId, RefreshTokenService.hash(bruto), AGORA.minusSeconds(60), expiraEm);
    }

    @Test
    void criar_persisteSomenteOHash_eExpiraNoPrazoConfigurado() {
        String bruto = service.criar(usuarioId);

        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(repositorio).save(captor.capture());
        RefreshToken salvo = captor.getValue();
        assertNotNull(bruto);
        assertNotEquals(bruto, salvo.getTokenHash());
        assertEquals(RefreshTokenService.hash(bruto), salvo.getTokenHash());
        assertEquals(64, salvo.getTokenHash().length());
        assertEquals(usuarioId, salvo.getUsuarioId());
        assertEquals(AGORA.plus(Duration.ofDays(30)), salvo.getExpiraEm());
    }

    @Test
    void criar_geraValoresDiferentesACadaChamada() {
        assertNotEquals(service.criar(usuarioId), service.criar(usuarioId));
    }

    @Test
    void rotacionar_tokenValido_revogaOAntigoECriaOutro() {
        RefreshToken atual = registro("token-valido", AGORA.plus(Duration.ofDays(10)));
        when(repositorio.findByTokenHash(RefreshTokenService.hash("token-valido"))).thenReturn(Optional.of(atual));
        when(repositorio.revogarSeAtivo(atual.getId(), AGORA)).thenReturn(1);

        RefreshTokenService.Rotacao rotacao = service.rotacionar("token-valido");

        assertEquals(usuarioId, rotacao.usuarioId());
        assertNotEquals("token-valido", rotacao.novoToken());
        verify(repositorio).revogarSeAtivo(atual.getId(), AGORA);
        verify(repositorio).save(any(RefreshToken.class));
        verify(repositorio, never()).revogarTodosDoUsuario(any(), any());
    }

    @Test
    void rotacionar_tokenDesconhecido_retorna401() {
        when(repositorio.findByTokenHash(RefreshTokenService.hash("lixo"))).thenReturn(Optional.empty());

        ApiException e = assertThrows(ApiException.class, () -> service.rotacionar("lixo"));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verify(repositorio, never()).save(any());
    }

    @Test
    void rotacionar_tokenExpirado_retorna401SemCriarOutro() {
        RefreshToken expirado = registro("token-velho", AGORA.minusSeconds(1));
        when(repositorio.findByTokenHash(RefreshTokenService.hash("token-velho"))).thenReturn(Optional.of(expirado));

        ApiException e = assertThrows(ApiException.class, () -> service.rotacionar("token-velho"));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verify(repositorio, never()).save(any());
    }

    @Test
    void rotacionar_tokenJaUsado_derrubaTodasAsSessoesDoUsuario() {
        RefreshToken usado = registro("token-usado", AGORA.plus(Duration.ofDays(10)));
        // A entidade não expõe setter (a revogação em produção é um UPDATE atômico); aqui simulamos o estado do banco.
        ReflectionTestUtils.setField(usado, "revogadoEm", AGORA.minusSeconds(30));
        when(repositorio.findByTokenHash(RefreshTokenService.hash("token-usado"))).thenReturn(Optional.of(usado));

        ApiException e = assertThrows(ApiException.class, () -> service.rotacionar("token-usado"));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verify(repositorio).revogarTodosDoUsuario(usuarioId, AGORA);
        verify(repositorio, never()).save(any());
    }

    @Test
    void rotacionar_corridaComOMesmoToken_soUmVence() {
        // Outro pedido revogou o token entre a leitura e o UPDATE: o UPDATE atômico retorna 0.
        RefreshToken atual = registro("token-corrida", AGORA.plus(Duration.ofDays(10)));
        when(repositorio.findByTokenHash(RefreshTokenService.hash("token-corrida"))).thenReturn(Optional.of(atual));
        when(repositorio.revogarSeAtivo(atual.getId(), AGORA)).thenReturn(0);

        ApiException e = assertThrows(ApiException.class, () -> service.rotacionar("token-corrida"));

        assertEquals(HttpStatus.UNAUTHORIZED, e.getStatus());
        verify(repositorio).revogarTodosDoUsuario(usuarioId, AGORA);
        verify(repositorio, never()).save(any());
    }

    @Test
    void revogar_tokenExistente_revogaUmaVez() {
        RefreshToken atual = registro("token-sair", AGORA.plus(Duration.ofDays(10)));
        when(repositorio.findByTokenHash(RefreshTokenService.hash("token-sair"))).thenReturn(Optional.of(atual));

        service.revogar("token-sair");

        verify(repositorio, times(1)).revogarSeAtivo(atual.getId(), AGORA);
    }

    @Test
    void revogar_tokenDesconhecido_naoEhErro() {
        when(repositorio.findByTokenHash(RefreshTokenService.hash("qualquer"))).thenReturn(Optional.empty());

        service.revogar("qualquer");

        verify(repositorio, never()).revogarSeAtivo(any(), any());
    }

    @Test
    void hash_ehSha256EmHexadecimalEEstavel() {
        // SHA-256 de "abc" (vetor de teste conhecido)
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                RefreshTokenService.hash("abc"));
    }
}
