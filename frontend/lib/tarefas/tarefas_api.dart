import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

/// O que o app precisa da API de tarefas e do plano de 7 dias. Interface para os testes trocarem a internet
/// por um servidor de mentira.
abstract class TarefasApi {
  /// O plano de 7 dias do objetivo, com todas as tarefas já agrupadas por dia.
  Future<Plano> plano(String accessToken, String objetivoId);

  Future<Tarefa> criar(String accessToken, String objetivoId, String titulo, int? dia);

  Future<Tarefa> atualizar(String accessToken, String id, String titulo, int? dia);

  Future<Tarefa> concluir(String accessToken, String id, bool concluida);

  Future<void> excluir(String accessToken, String id);
}

class HttpTarefasApi implements TarefasApi {
  HttpTarefasApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  static const _tempoLimite = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String caminho) => Uri.parse('$baseUrl/api/v1$caminho');

  Map<String, String> _cabecalhos(String accessToken, {bool json = false}) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
        if (json) 'Content-Type': 'application/json',
      };

  @override
  Future<Plano> plano(String accessToken, String objetivoId) async {
    final resposta = await _executar(
      () => _client.get(_uri('/objetivos/$objetivoId/plano'), headers: _cabecalhos(accessToken)),
    );
    return _ler(resposta, Plano.fromJson);
  }

  @override
  Future<Tarefa> criar(String accessToken, String objetivoId, String titulo, int? dia) async {
    final resposta = await _executar(
      () => _client.post(
        _uri('/objetivos/$objetivoId/tarefas'),
        headers: _cabecalhos(accessToken, json: true),
        body: jsonEncode({'titulo': titulo, 'dia': dia}),
      ),
    );
    return _ler(resposta, Tarefa.fromJson);
  }

  @override
  Future<Tarefa> atualizar(String accessToken, String id, String titulo, int? dia) async {
    final resposta = await _executar(
      () => _client.put(
        _uri('/tarefas/$id'),
        headers: _cabecalhos(accessToken, json: true),
        body: jsonEncode({'titulo': titulo, 'dia': dia}),
      ),
    );
    return _ler(resposta, Tarefa.fromJson);
  }

  @override
  Future<Tarefa> concluir(String accessToken, String id, bool concluida) async {
    final resposta = await _executar(
      () => _client.patch(
        _uri('/tarefas/$id/conclusao'),
        headers: _cabecalhos(accessToken, json: true),
        body: jsonEncode({'concluida': concluida}),
      ),
    );
    return _ler(resposta, Tarefa.fromJson);
  }

  @override
  Future<void> excluir(String accessToken, String id) async {
    await _executar(() => _client.delete(_uri('/tarefas/$id'), headers: _cabecalhos(accessToken)));
  }

  /// Mesma regra das outras APIs: só a chamada de rede fica no `try`, e qualquer falha ali
  /// (sem internet, CORS, tempo esgotado) vira um erro de conexão.
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

  T _ler<T>(http.Response resposta, T Function(Map<String, dynamic>) converter) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        return converter(corpo);
      }
    } on FormatException {
      // cai no erro abaixo
    } on TypeError {
      // campo faltando ou com tipo diferente do esperado
    }
    throw const ApiError('Resposta inesperada do servidor. Tente novamente.');
  }

  ApiError _erroDe(http.Response resposta) {
    if (resposta.statusCode >= 500) {
      return ApiError('O servidor teve um problema. Tente novamente em instantes.', status: resposta.statusCode);
    }
    var mensagem = 'Algo deu errado. Tente novamente em instantes.';
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final detalhe = corpo['detail'];
        if (detalhe is String && detalhe.isNotEmpty) {
          mensagem = detalhe;
        }
      }
    } on FormatException {
      // corpo vazio ou que não é JSON: ficamos com a mensagem padrão
    }
    return ApiError(mensagem, status: resposta.statusCode);
  }
}
