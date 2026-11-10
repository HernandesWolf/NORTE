import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';

/// Limites que o servidor também aplica. Respeitá-los aqui evita erro 400 por causa de uma conversa longa.
const int maxMensagensNoHistorico = 20;
const int maxCaracteresPorMensagem = 2000;

/// Quem escreveu uma mensagem da conversa.
enum PapelConversa {
  usuario('usuario'),
  assistente('assistente');

  const PapelConversa(this.rotulo);

  /// Como a API chama este papel.
  final String rotulo;
}

class MensagemConversa {
  const MensagemConversa({required this.papel, required this.texto});

  final PapelConversa papel;
  final String texto;
}

/// O que o app precisa da API de conversa. Interface para os testes trocarem a internet por um servidor de mentira.
abstract class ConversaApi {
  /// Manda a mensagem nova junto com o histórico recente (o servidor não guarda a conversa) e devolve a resposta.
  Future<String> responder(String accessToken, String mensagem, List<MensagemConversa> historico);
}

class HttpConversaApi implements ConversaApi {
  HttpConversaApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  /// A IA pode demorar mais do que as outras chamadas (o servidor espera até 30 s por ela).
  static const _tempoLimite = Duration(seconds: 45);

  final String baseUrl;
  final http.Client _client;

  @override
  Future<String> responder(String accessToken, String mensagem, List<MensagemConversa> historico) async {
    final recentes = historico
        .where((m) => m.texto.trim().isNotEmpty)
        .toList()
        .reversed
        .take(maxMensagensNoHistorico)
        .toList()
        .reversed;

    final corpo = jsonEncode({
      'mensagem': _cortar(mensagem),
      'historico': [
        for (final m in recentes) {'papel': m.papel.rotulo, 'texto': _cortar(m.texto)},
      ],
    });

    final resposta = await _executar(
      () => _client.post(
        Uri.parse('$baseUrl/api/v1/conversa'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: corpo,
      ),
    );
    return _lerResposta(resposta);
  }

  static String _cortar(String texto) {
    final limpo = texto.trim();
    return limpo.length > maxCaracteresPorMensagem ? limpo.substring(0, maxCaracteresPorMensagem) : limpo;
  }

  /// Só a chamada de rede fica no `try`: qualquer falha ali (sem internet, CORS, tempo esgotado) vira erro de conexão.
  Future<http.Response> _executar(Future<http.Response> Function() chamada) async {
    final http.Response resposta;
    try {
      resposta = await chamada().timeout(_tempoLimite);
    } on Exception {
      throw const ApiError.rede();
    }
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return resposta;
    }
    throw _erroDe(resposta);
  }

  String _lerResposta(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final texto = corpo['resposta'];
        if (texto is String && texto.trim().isNotEmpty) {
          return texto.trim();
        }
      }
    } on FormatException {
      // cai no erro abaixo
    }
    throw const ApiError('Resposta inesperada do servidor. Tente novamente.');
  }

  /// O servidor só manda mensagem segura para a pessoa nos erros esperados (limite de uso, IA fora do ar ou
  /// desligada). Em qualquer outro erro de servidor, mostramos um texto genérico.
  ApiError _erroDe(http.Response resposta) {
    final status = resposta.statusCode;
    final detalhe = _detalhe(resposta);
    final detalheEhSeguro = status < 500 || status == 502 || status == 503;
    if (detalhe != null && detalheEhSeguro) {
      return ApiError(detalhe, status: status);
    }
    if (status >= 500) {
      return ApiError('O servidor teve um problema. Tente novamente em instantes.', status: status);
    }
    return ApiError('Algo deu errado. Tente novamente em instantes.', status: status);
  }

  String? _detalhe(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final detalhe = corpo['detail'];
        if (detalhe is String && detalhe.isNotEmpty) {
          return detalhe;
        }
      }
    } on FormatException {
      // corpo vazio ou que não é JSON
    }
    return null;
  }
}
