package br.com.norte.checkins;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.com.norte.auth.JwtConfig;
import br.com.norte.auth.SecurityConfig;
import br.com.norte.auth.TokenService;
import br.com.norte.checkins.dto.CheckinResponse;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = CheckinController.class)
@Import({SecurityConfig.class, JwtConfig.class, TokenService.class})
@TestPropertySource(properties = {
        "norte.security.jwt.secret=segredo-de-teste-com-pelo-menos-32-bytes-ok!",
        "norte.security.jwt.access-token-ttl=15m",
        "norte.security.jwt.refresh-token-ttl=30d",
        "norte.cors.allowed-origin-patterns=http://localhost:*"
})
class CheckinControllerTest {

    private static final LocalDate DIA = LocalDate.of(2026, 11, 7);

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @MockitoBean
    private CheckinService checkinService;

    private String bearer(UUID usuarioId) {
        return "Bearer " + tokenService.emitir(usuarioId, "refresh-qualquer").accessToken();
    }

    @Test
    void consultar_semToken_retorna401() throws Exception {
        mockMvc.perform(get("/api/v1/checkins/hoje")).andExpect(status().isUnauthorized());

        verifyNoInteractions(checkinService);
    }

    @Test
    void registrar_semToken_retorna401() throws Exception {
        mockMvc.perform(put("/api/v1/checkins/hoje")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"COM_ENERGIA\"}"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(checkinService);
    }

    @Test
    void consultar_semCheckinHoje_retorna204() throws Exception {
        UUID id = UUID.randomUUID();
        when(checkinService.deHoje(id)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/checkins/hoje").header("Authorization", bearer(id)))
                .andExpect(status().isNoContent());
    }

    @Test
    void consultar_comCheckinHoje_retornaEstadoEDia() throws Exception {
        UUID id = UUID.randomUUID();
        when(checkinService.deHoje(id))
                .thenReturn(Optional.of(new CheckinResponse(EstadoCheckin.INDO_DEVAGAR, DIA, Instant.now())));

        mockMvc.perform(get("/api/v1/checkins/hoje").header("Authorization", bearer(id)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("INDO_DEVAGAR"))
                .andExpect(jsonPath("$.dia").value("2026-11-07"));
    }

    @Test
    void registrar_valido_usaOUsuarioDoTokenERetorna200() throws Exception {
        UUID id = UUID.randomUUID();
        when(checkinService.registrarHoje(id, EstadoCheckin.SOBRECARREGADO))
                .thenReturn(new CheckinResponse(EstadoCheckin.SOBRECARREGADO, DIA, Instant.now()));

        mockMvc.perform(put("/api/v1/checkins/hoje")
                        .header("Authorization", bearer(id))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"SOBRECARREGADO\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("SOBRECARREGADO"));

        verify(checkinService).registrarHoje(id, EstadoCheckin.SOBRECARREGADO);
    }

    @Test
    void registrar_estadoDesconhecido_retorna400() throws Exception {
        mockMvc.perform(put("/api/v1/checkins/hoje")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"estado\":\"FELIZ_DEMAIS\"}"))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(checkinService);
    }

    @Test
    void registrar_semEstado_retorna400ComDetalhe() throws Exception {
        mockMvc.perform(put("/api/v1/checkins/hoje")
                        .header("Authorization", bearer(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.erros.estado").exists());

        verifyNoInteractions(checkinService);
    }
}
