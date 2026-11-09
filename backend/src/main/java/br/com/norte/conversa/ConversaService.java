package br.com.norte.conversa;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ConversaService {
    private final MensagemConversaRepository mensagens;
    private final OpenAiResponsesClient ia;
    private final ConsentimentoIaRepository consentimentos;
    private final ControleUsoIaService controleUso;

    public ConversaService(
            MensagemConversaRepository mensagens,
            OpenAiResponsesClient ia,
            ConsentimentoIaRepository consentimentos,
            ControleUsoIaService controleUso) {
        this.mensagens = mensagens;
        this.ia = ia;
        this.consentimentos = consentimentos;
        this.controleUso = controleUso;
    }

    @Transactional(readOnly = true)
    public List<MensagemConversaResponse> listar(UUID usuarioId) {
        return mensagens.findTop100ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId)
                .stream()
                .sorted(Comparator.comparing(MensagemConversa::getCriadoEm)
                        .thenComparing(MensagemConversa::getId))
                .map(MensagemConversaResponse::de)
                .toList();
    }

    /**
     * A mensagem é persistida mesmo sem consentimento, mas nunca é enviada
     * à OpenAI sem habilitação global e consentimento individual vigente.
     */
    public MensagemConversaResponse registrar(UUID usuarioId, String conteudo) {
        MensagemConversa usuario = mensagens.save(
                new MensagemConversa(usuarioId, "USUARIO", conteudo.trim()));

        boolean consentido = consentimentos.findById(usuarioId)
                .map(ConsentimentoIa::isHabilitado)
                .orElse(false);
        if (!ia.habilitado() || !consentido) {
            return MensagemConversaResponse.de(usuario);
        }

        controleUso.reservar(usuarioId);

        List<MensagemConversa> contexto = mensagens
                .findTop12ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId)
                .stream()
                .sorted(Comparator.comparing(MensagemConversa::getCriadoEm)
                        .thenComparing(MensagemConversa::getId))
                .toList();

        String resposta = ia.responder(contexto);
        MensagemConversa norte = mensagens.save(
                new MensagemConversa(usuarioId, "NORTE", resposta));
        return MensagemConversaResponse.de(norte);
    }

    public PropostaObjetivoResponse proporObjetivo(UUID usuarioId) {
        boolean consentido = consentimentos.findById(usuarioId)
                .map(ConsentimentoIa::isHabilitado)
                .orElse(false);
        if (!ia.habilitado() || !consentido) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.FORBIDDEN,
                    "Autorize as respostas inteligentes antes de solicitar uma proposta.");
        }

        List<MensagemConversa> contexto = mensagens
                .findTop12ByUsuarioIdOrderByCriadoEmDescIdDesc(usuarioId)
                .stream()
                .sorted(Comparator.comparing(MensagemConversa::getCriadoEm)
                        .thenComparing(MensagemConversa::getId))
                .toList();
        if (contexto.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Converse com o NORTE antes de solicitar uma proposta.");
        }

        controleUso.reservar(usuarioId);
        return ia.proporObjetivo(contexto);
    }

    @Transactional(readOnly = true)
    public ConversaIaStatusResponse statusIa(UUID usuarioId) {
        boolean consentido = consentimentos.findById(usuarioId)
                .map(ConsentimentoIa::isHabilitado)
                .orElse(false);
        return new ConversaIaStatusResponse(
                ia.habilitado(),
                ia.habilitado() ? "OpenAI Responses API" : "desativada",
                consentido);
    }

    @Transactional
    public ConversaIaStatusResponse atualizarConsentimento(UUID usuarioId, boolean consentido) {
        ConsentimentoIa registro = consentimentos.findById(usuarioId)
                .orElseGet(() -> new ConsentimentoIa(usuarioId, consentido));
        registro.atualizar(consentido);
        consentimentos.save(registro);
        return statusIa(usuarioId);
    }
}
