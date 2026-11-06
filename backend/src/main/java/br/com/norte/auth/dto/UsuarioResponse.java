package br.com.norte.auth.dto;

import br.com.norte.usuarios.Usuario;
import java.util.UUID;

/** Dados públicos do próprio usuário. Nunca inclui a senha nem o hash. */
public record UsuarioResponse(UUID id, String email, String nomeExibicao) {

    public static UsuarioResponse de(Usuario u) {
        return new UsuarioResponse(u.getId(), u.getEmail(), u.getNomeExibicao());
    }
}
