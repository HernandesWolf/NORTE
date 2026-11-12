package br.com.norte.shared.config;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Com o perfil {@code prod} ativo, a aplicação se recusa a subir usando valores de desenvolvimento: senha do banco
 * padrão e CORS apontando para o próprio computador (ou aberto para qualquer origem). O segredo JWT já é validado
 * em {@code JwtConfig}.
 *
 * <p>Isso é feito em código, e não só no YAML, porque um {@code ${VARIAVEL}} sem valor padrão nem sempre derruba a
 * inicialização com uma mensagem útil: em alguns pontos o texto literal passa adiante e o erro só aparece depois,
 * longe da causa. Aqui a mensagem diz exatamente qual variável de ambiente falta.
 */
@Component
@Profile("prod")
public class ValidacaoDeProducao {

    static final String SENHA_DEV_DO_BANCO = "norte_dev";

    public ValidacaoDeProducao(Environment env) {
        validar(env);
    }

    static void validar(Environment env) {
        List<String> problemas = new ArrayList<>();

        String senhaDoBanco = env.getProperty("spring.datasource.password");
        if (senhaDoBanco == null || senhaDoBanco.isBlank() || SENHA_DEV_DO_BANCO.equals(senhaDoBanco)) {
            problemas.add("NORTE_DB_PASSWORD: defina a senha real do banco (a senha de desenvolvimento não é aceita).");
        }

        String cors = env.getProperty("norte.cors.allowed-origin-patterns", "");
        if (corsInseguro(cors)) {
            problemas.add("NORTE_CORS_ORIGINS: defina o(s) domínio(s) reais do app, por exemplo "
                    + "https://app.exemplo.com.br (localhost, 127.0.0.1 e \"*\" não são aceitos em produção).");
        }

        if (!problemas.isEmpty()) {
            throw new IllegalStateException(
                    "Configuração de produção insegura. Ajuste as variáveis de ambiente:\n- "
                            + String.join("\n- ", problemas));
        }
    }

    private static boolean corsInseguro(String cors) {
        if (cors.isBlank()) {
            return true;
        }
        return Arrays.stream(cors.split(","))
                .map(String::trim)
                .anyMatch(origem -> origem.equals("*")
                        || origem.contains("localhost")
                        || origem.contains("127.0.0.1"));
    }
}
