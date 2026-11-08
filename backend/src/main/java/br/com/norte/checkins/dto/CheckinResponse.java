package br.com.norte.checkins.dto;

import br.com.norte.checkins.Checkin;
import br.com.norte.checkins.EstadoCheckin;
import java.time.Instant;
import java.time.LocalDate;

public record CheckinResponse(EstadoCheckin estado, LocalDate dia, Instant atualizadoEm) {

    public static CheckinResponse de(Checkin c) {
        return new CheckinResponse(c.getEstado(), c.getDia(), c.getAtualizadoEm());
    }
}
