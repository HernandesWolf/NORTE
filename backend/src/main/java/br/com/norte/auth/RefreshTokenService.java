package br.com.norte.auth;

import br.com.norte.shared.error.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Refresh tokens opacos (aleatórios), com rotação: cada renovação invalida o token usado e emite outro.
 * Se alguém apresentar um token que já foi usado, tratamos como possível roubo e derrubamos todas as sessões.
 */
@Service
public class RefreshTokenService {

    private static final int TAMANHO_EM_BYTES = 32;
    private static final String MSG_SESSAO_INVALIDA = "Sessão inválida ou expirada. Entre novamente.";

    private final RefreshTokenRepository repositorio;
    private final JwtProperties props;
    private final Clock relogio;
    private final SecureRandom aleatorio = new SecureRandom();

    public RefreshTokenService(RefreshTokenRepository repositorio, JwtProperties props, Clock relogio) {
        this.repositorio = repositorio;
        this.props = props;
        this.relogio = relogio;
    }

    /** Resultado de uma rotação: de quem é a sessão e qual é o novo refresh token (valor bruto). */
    public record Rotacao(UUID usuarioId, String novoToken) {}

    /** Cria uma sessão nova e devolve o valor bruto (única vez em que ele existe fora do cliente). */
    @Transactional
    public String criar(UUID usuarioId) {
        String bruto = gerarTokenOpaco();
        Instant agora = relogio.instant();
        repositorio.save(new RefreshToken(usuarioId, hash(bruto), agora, agora.plus(props.refreshTokenTtl())));
        return bruto;
    }

    /**
     * Troca um refresh token válido por um novo. O {@code noRollbackFor} é essencial: quando detectamos reuso,
     * lançamos 401 e, mesmo assim, a revogação de todas as sessões precisa ser gravada.
     */
    @Transactional(noRollbackFor = ApiException.class)
    public Rotacao rotacionar(String brutoApresentado) {
        RefreshToken atual = repositorio.findByTokenHash(hash(brutoApresentado))
                .orElseThrow(() -> ApiException.naoAutorizado(MSG_SESSAO_INVALIDA));
        Instant agora = relogio.instant();

        if (atual.getRevogadoEm() != null) {
            repositorio.revogarTodosDoUsuario(atual.getUsuarioId(), agora);
            throw ApiException.naoAutorizado(MSG_SESSAO_INVALIDA);
        }
        if (!atual.getExpiraEm().isAfter(agora)) {
            throw ApiException.naoAutorizado(MSG_SESSAO_INVALIDA);
        }
        // Se duas requisições chegarem juntas com o mesmo token, só uma consegue revogar (retorno 1).
        if (repositorio.revogarSeAtivo(atual.getId(), agora) == 0) {
            repositorio.revogarTodosDoUsuario(atual.getUsuarioId(), agora);
            throw ApiException.naoAutorizado(MSG_SESSAO_INVALIDA);
        }
        return new Rotacao(atual.getUsuarioId(), criar(atual.getUsuarioId()));
    }

    /** Encerra a sessão. Idempotente: um token desconhecido ou já revogado não é erro (o objetivo já foi atingido). */
    @Transactional
    public void revogar(String brutoApresentado) {
        Optional<RefreshToken> encontrado = repositorio.findByTokenHash(hash(brutoApresentado));
        encontrado.ifPresent(t -> repositorio.revogarSeAtivo(t.getId(), relogio.instant()));
    }

    private String gerarTokenOpaco() {
        byte[] bytes = new byte[TAMANHO_EM_BYTES];
        aleatorio.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hash(String valor) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(valor.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            // SHA-256 é obrigatório em toda JVM; chegar aqui indica ambiente quebrado.
            throw new IllegalStateException("SHA-256 indisponível nesta JVM.", e);
        }
    }
}
