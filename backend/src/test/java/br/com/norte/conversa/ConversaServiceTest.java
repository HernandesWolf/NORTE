package br.com.norte.conversa;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ConversaServiceTest {
    @Mock private MensagemConversaRepository mensagens;
    @Mock private OpenAiResponsesClient ia;
    @Mock private ConsentimentoIaRepository consentimentos;
    @Mock private ControleUsoIaService controleUso;
    @InjectMocks private ConversaService service;

    @Test
    void registraMensagemSemEnviarParaIaQuandoUsuarioNaoConsentiu() {
        UUID usuarioId = UUID.randomUUID();
        when(mensagens.save(any(MensagemConversa.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));
        when(ia.habilitado()).thenReturn(true);
        when(consentimentos.findById(usuarioId)).thenReturn(Optional.empty());

        MensagemConversaResponse resposta = service.registrar(usuarioId, "  Preciso organizar minha semana  ");

        assertEquals("USUARIO", resposta.papel());
        assertEquals("Preciso organizar minha semana", resposta.conteudo());
        verify(ia, never()).responder(anyList());
        verify(controleUso, never()).reservar(usuarioId);
    }

    @Test
    void chamaIaERegistraRespostaSomenteComConsentimento() {
        UUID usuarioId = UUID.randomUUID();
        when(mensagens.save(any(MensagemConversa.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));
        when(ia.habilitado()).thenReturn(true);
        when(consentimentos.findById(usuarioId))
                .thenReturn(Optional.of(new ConsentimentoIa(usuarioId, true)));
        when(mensagens.findTop12ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId))
                .thenAnswer(invocacao -> List.of(new MensagemConversa(
                        usuarioId, "USUARIO", "Quero mudar de carreira.")));
        when(ia.responder(anyList())).thenReturn("Vamos organizar esse caminho.");

        MensagemConversaResponse resposta = service.registrar(usuarioId, "Quero mudar de carreira.");

        assertEquals("NORTE", resposta.papel());
        assertEquals("Vamos organizar esse caminho.", resposta.conteudo());
        verify(controleUso).reservar(usuarioId);
        verify(mensagens, org.mockito.Mockito.times(2)).save(any(MensagemConversa.class));
    }

    @Test
    void statusInformaConsentimentoIndividual() {
        UUID usuarioId = UUID.randomUUID();
        when(ia.habilitado()).thenReturn(false);
        when(consentimentos.findById(usuarioId))
                .thenReturn(Optional.of(new ConsentimentoIa(usuarioId, true)));

        ConversaIaStatusResponse status = service.statusIa(usuarioId);

        assertEquals(false, status.habilitada());
        assertEquals(true, status.consentimentoUsuario());
    }
}
