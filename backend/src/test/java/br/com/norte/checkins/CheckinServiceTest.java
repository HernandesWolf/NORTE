package br.com.norte.checkins;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.com.norte.checkins.dto.CheckinResponse;
import br.com.norte.shared.error.ApiException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;

@ExtendWith(MockitoExtension.class)
class CheckinServiceTest {

    /** 02:30 UTC de 8/11 ainda é 23:30 de 7/11 em Brasília: o "dia" tem que seguir o fuso, não o UTC. */
    private static final Instant AGORA = Instant.parse("2026-11-08T02:30:00Z");

    private static final LocalDate HOJE_EM_BRASILIA = LocalDate.of(2026, 11, 7);

    @Mock
    private CheckinRepository repositorio;

    private CheckinService servico;
    private final UUID usuarioId = UUID.randomUUID();

    @BeforeEach
    void preparar() {
        Clock relogio = Clock.fixed(AGORA, ZoneOffset.UTC);
        servico = new CheckinService(repositorio, relogio, "America/Sao_Paulo");
    }

    @Test
    void deHoje_semCheckin_retornaVazio() {
        when(repositorio.findByUsuarioIdAndDia(usuarioId, HOJE_EM_BRASILIA)).thenReturn(Optional.empty());

        assertTrue(servico.deHoje(usuarioId).isEmpty());
    }

    @Test
    void deHoje_comCheckin_retornaEstadoEDia() {
        Checkin salvo = new Checkin(usuarioId, HOJE_EM_BRASILIA, EstadoCheckin.INDO_DEVAGAR, AGORA);
        when(repositorio.findByUsuarioIdAndDia(usuarioId, HOJE_EM_BRASILIA)).thenReturn(Optional.of(salvo));

        CheckinResponse resposta = servico.deHoje(usuarioId).orElseThrow();

        assertEquals(EstadoCheckin.INDO_DEVAGAR, resposta.estado());
        assertEquals(HOJE_EM_BRASILIA, resposta.dia());
    }

    @Test
    void registrarHoje_gravaNoDiaDoFusoConfigurado() {
        Checkin salvo = new Checkin(usuarioId, HOJE_EM_BRASILIA, EstadoCheckin.SOBRECARREGADO, AGORA);
        when(repositorio.findByUsuarioIdAndDia(usuarioId, HOJE_EM_BRASILIA)).thenReturn(Optional.of(salvo));

        CheckinResponse resposta = servico.registrarHoje(usuarioId, EstadoCheckin.SOBRECARREGADO);

        verify(repositorio).registrar(usuarioId, HOJE_EM_BRASILIA, "SOBRECARREGADO", AGORA);
        assertEquals(EstadoCheckin.SOBRECARREGADO, resposta.estado());
        assertEquals(HOJE_EM_BRASILIA, resposta.dia());
    }

    @Test
    void registrarHoje_usuarioInexistente_retorna401() {
        when(repositorio.registrar(any(), any(), anyString(), any()))
                .thenThrow(new DataIntegrityViolationException("fk violada"));

        ApiException erro = assertThrows(
                ApiException.class, () -> servico.registrarHoje(usuarioId, EstadoCheckin.COM_ENERGIA));

        assertEquals(HttpStatus.UNAUTHORIZED, erro.getStatus());
    }
}
