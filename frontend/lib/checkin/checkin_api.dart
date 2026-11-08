import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/checkin/checkin_models.dart';

/// O que o app precisa da API de check-in. Interface para os testes trocarem a internet por um servidor de mentira.
abstract class CheckinApi {
  /// O estado que a pessoa escolheu hoje, ou `null` se ainda não escolheu.
  Future<EstadoCheckin?> deHoje(String accessToken);

  /// Grava (ou troca) o estado de hoje e devolve o que o servidor guardou.
  Future<EstadoCheckin> registrar(String accessToken, EstadoCheckin estado);
}

class HttpCheckinApi implements CheckinApi {
  HttpCheckinApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

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
  Future<EstadoCheckin?> deHoje(String accessToken) async {
    final resposta = await _executar(
      () => _client.get(_uri('/checkins/hoje'), headers: _cabecalhos(accessToken)),
    );
    if (resposta.statusCode == 204) {
      return null;
    }
    return _estadoDe(resposta);
  }

  @override
  Future<EstadoCheckin> registrar(String accessToken, EstadoCheckin estado) async {
    final resposta = await _executar(
      () => _client.put(
        _uri('/checkins/hoje'),
        headers: _cabecalhos(accessToken, json: true),
        body: jsonEncode({'estado': estado.codigo}),
      ),
    );
    return _estadoDe(resposta);
  }

  /// Mesma regra da API de autenticação: só a chamada de rede fica no `try`, e qualquer falha ali
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

  EstadoCheckin _estadoDe(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final estado = EstadoCheckin.deCodigo(corpo['estado']);
        if (estado != null) {
          return estado;
        }
      }
    } on FormatException {
      // cai no erro abaixo
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
