package br.com.norte.conversa;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;

class ControleUsoIaServiceTest {
    private JdbcTemplate jdbc;
    private ControleUsoIaService service;

    @BeforeEach
    void configurar() {
        jdbc = org.mockito.Mockito.mock(JdbcTemplate.class);
        service = new ControleUsoIaService(jdbc, 2, 5);
    }

    @Test
    void reservaChamadaQuandoAmbosOsLimitesPermitem() {
        when(jdbc.update(anyString(), any(Object[].class))).thenReturn(1);

        service.reservar(UUID.randomUUID());

        org.mockito.Mockito.verify(jdbc, org.mockito.Mockito.times(2))
                .update(anyString(), any(Object[].class));
    }

    @Test
    void bloqueiaQuandoLimiteDiarioDoUsuarioFoiAtingido() {
        when(jdbc.update(anyString(), any(Object[].class))).thenReturn(0);

        assertThrows(ResponseStatusException.class, () -> service.reservar(UUID.randomUUID()));
        org.mockito.Mockito.verify(jdbc, org.mockito.Mockito.times(1))
                .update(anyString(), any(Object[].class));
    }

    @Test
    void bloqueiaQuandoLimiteMensalGlobalFoiAtingido() {
        when(jdbc.update(anyString(), any(Object[].class))).thenReturn(1, 0);

        assertThrows(ResponseStatusException.class, () -> service.reservar(UUID.randomUUID()));
        org.mockito.Mockito.verify(jdbc, org.mockito.Mockito.times(2))
                .update(anyString(), any(Object[].class));
    }
}
