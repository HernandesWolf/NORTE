import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/core/token_storage.dart';

/// O que o app precisa da API de autenticação. Existe como interface para os testes
/// poderem trocar a internet por um servidor de mentira.
abstract class AuthApi {
  Future<Usuario> registrar({required String email, required String senha, String? nome});
  Future<Sessao> entrar({required String email, required String senha});
  Future<Sessao> renovar(String refreshToken);
  Future<void> sair(String refreshToken);
  Future<Usuario> perfil(String accessToken);
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  static const _tempoLimite = Duration(seconds: 15);
  static const _cabecalhosJson = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String caminho) => Uri.parse('$baseUrl/api/v1$caminho');

  @override
  Future<Usuario> registrar({required String email, required String senha, String? nome}) async {
    final corpo = <String, dynamic>{'email': email, 'senha': senha};
    if (nome != null && nome.isNotEmpty) {
      corpo['nomeExibicao'] = nome;
    }
    final resposta = await _executar(
      () => _client.post(_uri('/auth/registro'), headers: _cabecalhosJson, body: jsonEncode(corpo)),
    );
    return Usuario.fromJson(_json(resposta));
  }

  @override
  Future<Sessao> entrar({required String email, required String senha}) async {
    final resposta = await _executar(
      () => _client.post(
        _uri('/auth/login'),
        headers: _cabecalhosJson,
        body: jsonEncode({'email': email, 'senha': senha}),
      ),
    );
    return _sessaoDe(resposta);
  }

  @override
  Future<Sessao> renovar(String refreshToken) async {
    final resposta = await _executar(
      () => _client.post(
        _uri('/auth/refresh'),
        headers: _cabecalhosJson,
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );
    return _sessaoDe(resposta);
  }

  @override
  Future<void> sair(String refreshToken) async {
    await _executar(
      () => _client.post(
        _uri('/auth/logout'),
        headers: _cabecalhosJson,
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );
  }

  @override
  Future<Usuario> perfil(String accessToken) async {
    final resposta = await _executar(
      () => _client.get(
        _uri('/me'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $accessToken'},
      ),
    );
    return Usuario.fromJson(_json(resposta));
  }

  /// Faz a chamada e transforma qualquer falha em [ApiError]. Só a chamada de rede fica dentro do `try`:
  /// qualquer exceção ali (sem internet, DNS, CORS, tempo esgotado) é, na prática, um problema de conexão.
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

  Sessao _sessaoDe(http.Response resposta) {
    final json = _json(resposta);
    final acesso = json['accessToken'];
    final renovacao = json['refreshToken'];
    if (acesso is! String || renovacao is! String) {
      throw const ApiError('Resposta inesperada do servidor. Tente novamente.');
    }
    return Sessao(accessToken: acesso, refreshToken: renovacao);
  }

  Map<String, dynamic> _json(http.Response resposta) {
    try {
      // Decodificamos os bytes como UTF-8 de propósito: `resposta.body` assumiria Latin-1 sem `charset`.
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        return corpo;
      }
    } on FormatException {
      // cai no erro abaixo
    }
    throw const ApiError('Resposta inesperada do servidor. Tente novamente.');
  }

  /// A API devolve erros no formato RFC 7807: `detail` com a mensagem e, na validação, `erros` por campo.
  ApiError _erroDe(http.Response resposta) {
    var mensagem = 'Algo deu errado. Tente novamente em instantes.';
    var erros = const <String, String>{};
    if (resposta.statusCode < 500) {
      try {
        final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (corpo is Map<String, dynamic>) {
          final detalhe = corpo['detail'];
          if (detalhe is String && detalhe.isNotEmpty) {
            mensagem = detalhe;
          }
          final porCampo = corpo['erros'];
          if (porCampo is Map) {
            erros = porCampo.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        }
      } on FormatException {
        // corpo vazio ou que não é JSON: ficamos com a mensagem padrão
      }
    } else {
      mensagem = 'O servidor teve um problema. Tente novamente em instantes.';
    }
    return ApiError(mensagem, status: resposta.statusCode, erros: erros);
  }
}
