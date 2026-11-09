package br.com.norte.conversa;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
public class ControleUsoIaService {
    private final JdbcTemplate jdbc;
    private final int limiteDiarioUsuario;
    private final int limiteMensalGlobal;

    public ControleUsoIaService(
            JdbcTemplate jdbc,
            @Value("${norte.ia.limites.diario-usuario:10}") int limiteDiarioUsuario,
            @Value("${norte.ia.limites.mensal-global:1000}") int limiteMensalGlobal) {
        this.jdbc = jdbc;
        this.limiteDiarioUsuario = Math.max(1, limiteDiarioUsuario);
        this.limiteMensalGlobal = Math.max(1, limiteMensalGlobal);
    }

    /**
     * Reserva a chamada de forma atômica no PostgreSQL. Se qualquer limite
     * for excedido, a exceção reverte as duas atualizações da transação.
     */
    @Transactional
    public void reservar(UUID usuarioId) {
        int usuario = jdbc.update("""
                INSERT INTO ia_uso_diario_usuario (usuario_id, dia, chamadas)
                VALUES (?, CURRENT_DATE, 1)
                ON CONFLICT (usuario_id, dia)
                DO UPDATE SET chamadas = ia_uso_diario_usuario.chamadas + 1
                WHERE ia_uso_diario_usuario.chamadas < ?
                """, usuarioId, limiteDiarioUsuario);

        if (usuario == 0) {
            throw new ResponseStatusException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Você atingiu o limite diário de respostas inteligentes. Tente novamente amanhã.");
        }

        int global = jdbc.update("""
                INSERT INTO ia_uso_mensal_global (mes, chamadas)
                VALUES (date_trunc('month', CURRENT_DATE)::date, 1)
                ON CONFLICT (mes)
                DO UPDATE SET chamadas = ia_uso_mensal_global.chamadas + 1
                WHERE ia_uso_mensal_global.chamadas < ?
                """, limiteMensalGlobal);

        if (global == 0) {
            throw new ResponseStatusException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "O limite mensal de respostas inteligentes foi atingido. O serviço será retomado no próximo mês.");
        }
    }
}
