package br.com.norte.auth;

import br.com.norte.auth.dto.LoginRequest;
import br.com.norte.auth.dto.RegistroRequest;
import br.com.norte.auth.dto.TokenResponse;
import br.com.norte.auth.dto.UsuarioResponse;
import br.com.norte.shared.error.ApiException;
import br.com.norte.usuarios.Usuario;
import br.com.norte.usuarios.UsuarioRepository;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    /** BCrypt só considera os primeiros 72 bytes da senha. */
    private static final int MAX_BYTES_SENHA = 72;

    private static final String MSG_CREDENCIAIS = "E-mail ou senha inválidos.";

    private final UsuarioRepository usuarios;
    private final PasswordEncoder encoder;
    private final TokenService tokens;
    /** Hash descartável, usado para gastar o mesmo tempo quando o e-mail não existe. */
    private final String hashFalso;

    public AuthService(UsuarioRepository usuarios, PasswordEncoder encoder, TokenService tokens) {
        this.usuarios = usuarios;
        this.encoder = encoder;
        this.tokens = tokens;
        this.hashFalso = encoder.encode("senha-descartavel-para-igualar-tempo");
    }

    @Transactional
    public UsuarioResponse registrar(RegistroRequest req) {
        String email = normalizarEmail(req.email());
        if (excedeLimiteBcrypt(req.senha())) {
            throw ApiException.requisicaoInvalida(
                    "A senha é longa demais (máximo de 72 bytes). Evite muitos caracteres especiais.");
        }
        if (usuarios.existsByEmail(email)) {
            throw ApiException.conflito("Este e-mail já está cadastrado.");
        }
        Usuario novo = new Usuario(email, encoder.encode(req.senha()), limparNome(req.nomeExibicao()));
        try {
            return UsuarioResponse.de(usuarios.saveAndFlush(novo));
        } catch (DataIntegrityViolationException e) {
            // Duas requisições simultâneas com o mesmo e-mail: o banco garante a unicidade.
            throw ApiException.conflito("Este e-mail já está cadastrado.");
        }
    }

    @Transactional(readOnly = true)
    public TokenResponse login(LoginRequest req) {
        Optional<Usuario> encontrado = usuarios.findByEmail(normalizarEmail(req.email()));
        if (excedeLimiteBcrypt(req.senha())) {
            throw ApiException.naoAutorizado(MSG_CREDENCIAIS);
        }
        String hash = encontrado.map(Usuario::getSenhaHash).orElse(hashFalso);
        boolean senhaConfere = encoder.matches(req.senha(), hash);
        if (encontrado.isEmpty() || !senhaConfere) {
            throw ApiException.naoAutorizado(MSG_CREDENCIAIS);
        }
        return tokens.emitir(encontrado.get().getId());
    }

    @Transactional(readOnly = true)
    public UsuarioResponse perfil(UUID usuarioId) {
        return usuarios.findById(usuarioId)
                .map(UsuarioResponse::de)
                .orElseThrow(() -> ApiException.naoAutorizado("Sessão inválida."));
    }

    private static String normalizarEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static String limparNome(String nome) {
        if (nome == null || nome.isBlank()) {
            return null;
        }
        return nome.trim();
    }

    private static boolean excedeLimiteBcrypt(String senha) {
        return senha.getBytes(StandardCharsets.UTF_8).length > MAX_BYTES_SENHA;
    }
}
