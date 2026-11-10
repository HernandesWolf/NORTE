import 'dart:async';

import 'package:norte_app/conversa/conversa_api.dart';

/// Servidor de mentira da conversa: responde na hora, a não ser que o teste peça outra coisa.
class FakeConversaApi implements ConversaApi {
  FakeConversaApi({this.resposta = 'Estou aqui com você.'});

  /// O que a IA "responde".
  String resposta;

  /// Se preenchido, a próxima chamada falha com este erro.
  Object? falha;

  /// Se preenchido, a chamada fica esperando até o teste completar (para olhar a tela "pensando").
  Completer<String>? pendente;

  final List<({String mensagem, List<MensagemConversa> historico})> chamadas = [];

  @override
  Future<String> responder(String accessToken, String mensagem, List<MensagemConversa> historico) async {
    chamadas.add((mensagem: mensagem, historico: historico));
    final erro = falha;
    if (erro != null) {
      throw erro;
    }
    final espera = pendente;
    if (espera != null) {
      return espera.future;
    }
    return resposta;
  }
}
