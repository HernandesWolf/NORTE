import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';

class Objetivo {
  const Objetivo({required this.id, required this.titulo, this.descricao, required this.concluido});

  factory Objetivo.fromJson(Map<String, dynamic> json) => Objetivo(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String?,
    concluido: json['concluido'] as bool? ?? false,
  );

  final String id;
  final String titulo;
  final String? descricao;
  final bool concluido;
}

class ObjetivosApi {
  ObjetivosApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;

  Uri _uri([String sufixo = '']) => Uri.parse('$baseUrl/api/v1/objetivos$sufixo');
  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<Objetivo>> listar(String token) async {
    final response = await _request(() => _client.get(_uri(), headers: _headers(token)));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data.map((item) => Objetivo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Objetivo> criar(String token, String titulo, String? descricao) async {
    final response = await _request(() => _client.post(_uri(), headers: _headers(token),
      body: jsonEncode({'titulo': titulo, 'descricao': descricao})));
    return Objetivo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  Future<Objetivo> concluir(String token, String id, bool concluido) async {
    final response = await _request(() => _client.patch(_uri('/$id/conclusao'), headers: _headers(token),
      body: jsonEncode({'concluido': concluido})));
    return Objetivo.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  Future<void> excluir(String token, String id) async {
    await _request(() => _client.delete(_uri('/$id'), headers: _headers(token)));
  }

  Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      final response = await call().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) return response;
      var message = 'Não foi possível salvar seus objetivos.';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['detail'] is String) message = body['detail'] as String;
      } catch (_) {}
      throw ApiError(message, status: response.statusCode);
    } on ApiError {
      rethrow;
    } on Exception {
      throw const ApiError.rede();
    }
  }
}
