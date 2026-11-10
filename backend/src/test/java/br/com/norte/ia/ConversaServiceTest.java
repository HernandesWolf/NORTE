package br.com.norte.ia;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import br.com.norte.shared.error.ApiException;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;

class ConversaServiceTest {

    private AiGateway gateway;
    private LimitadorDeUsoIa limitador;
    private ConversaService servico;
    private final UUID pessoa = UUID.randomUUID();

    @BeforeEach
    void preparar() {
        gateway = mock(AiGateway.class);
        limitador = mock(LimitadorDeUsoIa.class);
        servico = new ConversaService(gateway, limitador);
    }

    @SuppressWarnings("unchecked")
    private List<MensagemIa> conversaEnviadaAoGateway() {
        ArgumentCaptor<List<MensagemIa>> captor = ArgumentCaptor.forClass(List.class);
        verify(gateway).responder(eq(PromptNorte.INSTRUCAO), captor.capture());
        return captor.getValue();
    }

    @Test
    void devolveAResposta_eRegistraOUsoDaPessoaDoToken() {
        when(gateway.responder(any(), any())).thenReturn("Estou aqui com você.");

        ConversaResponse resposta = servico.responder(pessoa, new ConversaRequest("Estou cansada", null));

        assertEquals("Estou aqui com você.", resposta.resposta());
        verify(limitador).registrar(pessoa);
    }

    @Test
    void semHistorico_enviaSoAMensagemDaPessoa_semEspacosNasPontas() {
        when(gateway.responder(any(), any())).thenReturn("ok");

        servico.responder(pessoa, new ConversaRequest("  Preciso de direção  ", null));

        List<MensagemIa> conversa = conversaEnviadaAoGateway();
        assertEquals(List.of(new MensagemIa(MensagemIa.Papel.USUARIO, "Preciso de direção")), conversa);
    }

    @Test
    void historico_entraEmOrdem_eAMensagemNovaVaiPorUltimo() {
        when(gateway.responder(any(), any())).thenReturn("ok");
        List<MensagemRequest> historico = List.of(
                new MensagemRequest("usuario", "Oi"),
                new MensagemRequest("assistente", "Olá! O que é importante hoje?"),
                new MensagemRequest("usuario", " Estou sobrecarregada "));

        servico.responder(pessoa, new ConversaRequest("Não sei por onde começar", historico));

        assertEquals(
                List.of(
                        new MensagemIa(MensagemIa.Papel.USUARIO, "Oi"),
                        new MensagemIa(MensagemIa.Papel.ASSISTENTE, "Olá! O que é importante hoje?"),
                        new MensagemIa(MensagemIa.Papel.USUARIO, "Estou sobrecarregada"),
                        new MensagemIa(MensagemIa.Papel.USUARIO, "Não sei por onde começar")),
                conversaEnviadaAoGateway());
    }

    @Test
    void respostaSoltaDaIaNoInicioDoHistorico_eIgnorada() {
        when(gateway.responder(any(), any())).thenReturn("ok");
        List<MensagemRequest> historico = List.of(
                new MensagemRequest("assistente", "Estou aqui para ajudar."),
                new MensagemRequest("usuario", "Oi"));

        servico.responder(pessoa, new ConversaRequest("Tudo bem?", historico));

        List<MensagemIa> conversa = conversaEnviadaAoGateway();
        assertEquals(MensagemIa.Papel.USUARIO, conversa.get(0).papel());
        assertEquals(2, conversa.size());
    }

    @Test
    void limiteEstourado_naoChamaAIaNemCobraNada() {
        doThrow(ApiException.muitasTentativas("Muitas mensagens.", 60)).when(limitador).registrar(pessoa);

        ApiException e = assertThrows(
                ApiException.class, () -> servico.responder(pessoa, new ConversaRequest("Oi", null)));

        assertEquals(HttpStatus.TOO_MANY_REQUESTS, e.getStatus());
        verifyNoInteractions(gateway);
    }

    @Test
    void falhaDaIa_chegaComoEstaParaOTratadorDeErros() {
        ApiException falha = new ApiException(HttpStatus.BAD_GATEWAY, "Não consegui falar com a IA agora.");
        when(gateway.responder(any(), any())).thenThrow(falha);

        ApiException e = assertThrows(
                ApiException.class, () -> servico.responder(pessoa, new ConversaRequest("Oi", null)));

        assertSame(falha, e);
    }
}
