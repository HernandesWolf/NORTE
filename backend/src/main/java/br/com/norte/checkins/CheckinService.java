package br.com.norte.checkins;

import br.com.norte.checkins.dto.CheckinResponse;
import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CheckinService {

    private final CheckinRepository repositorio;
    private final Clock relogio;
    /** Fuso que define "hoje" para a pessoa. No piloto (Brasil) o padrão é o horário de Brasília. */
    private final ZoneId fuso;

    public CheckinService(
            CheckinRepository repositorio,
            Clock relogio,
            @Value("${norte.fuso-horario:America/Sao_Paulo}") String fuso) {
        this.repositorio = repositorio;
        this.relogio = relogio;
        this.fuso = ZoneId.of(fuso);
    }

    @Transactional(readOnly = true)
    public Optional<CheckinResponse> deHoje(UUID usuarioId) {
        return repositorio.findByUsuarioIdAndDia(usuarioId, hoje()).map(CheckinResponse::de);
    }

    /** Registra (ou troca) o estado de hoje. Escolher de novo no mesmo dia atualiza, não duplica. */
    @Transactional
    public CheckinResponse registrarHoje(UUID usuarioId, EstadoCheckin estado) {
        LocalDate dia = hoje();
        try {
            repositorio.registrar(usuarioId, dia, estado.name(), relogio.instant());
        } catch (DataIntegrityViolationException e) {
            // Token válido de um usuário que já não existe (conta excluída): a sessão não vale mais.
            throw ApiException.naoAutorizado("Sessão inválida.");
        }
        return repositorio.findByUsuarioIdAndDia(usuarioId, dia)
                .map(CheckinResponse::de)
                .orElseThrow(() -> new IllegalStateException("Check-in não encontrado logo após gravar."));
    }

    private LocalDate hoje() {
        return LocalDate.now(relogio.withZone(fuso));
    }
}
