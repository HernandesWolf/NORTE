import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:norte_app/auth/auth_models.dart';

class MensagemConversa {
  const MensagemConversa({
    required this.id,
    required this.papel,
    required this.conteudo,
    required this.criadoEm,
  });

  factory MensagemConversa.fromJson(Map<String, dynamic> json) => MensagemConversa(
        id: json['id'] as String,
        papel: json['papel'] as String,
        conteudo: json['conteudo'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  final String id;
  final String papel;
  final String conteudo;
  final DateTime criadoEm;

  bool get enviadaPeloUsuario => papel == 'USUARIO';
}

class ConversaIaStatus {
  const ConversaIaStatus({
    required this.habilitada,
    required this.provedor,
    required this.consentimentoUsuario,
  });

  factory ConversaIaStatus.fromJson(Map<String, dynamic> json) => ConversaIaStatus(
        habilitada: json['habilitada'] as bool? ?? false,
        provedor: json['provedor'] as String? ?? 'desativada',
        consentimentoUsuario: json['consentimentoUsuario'] as bool? ?? false,
      );

  final bool habilitada;
  final String provedor;
  final bool consentimentoUsuario;
}

class ConversaApi {
  ConversaApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri get _uri => Uri.parse('$baseUrl/api/v1/conversa/mensagens');
  Uri get _statusUri => Uri.parse('$baseUrl/api/v1/conversa/ia/status');
  Uri get _consentimentoUri => Uri.parse('$baseUrl/api/v1/conversa/ia/consentimento');

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<MensagemConversa>> listar(String token) async {
    final response = await _request(
      () => _client.get(_uri, headers: _headers(token)),
    );
    final dados = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return dados
        .map((item) => MensagemConversa.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MensagemConversa> enviar(String token, String conteudo) async {
    final response = await _request(
      () => _client.post(
        _uri,
        headers: _headers(token),
        body: jsonEncode({'conteudo': conteudo}),
      ),
    );
    return MensagemConversa.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<ConversaIaStatus> statusIa(String token) async {
    final response = await _request(
      () => _client.get(_statusUri, headers: _headers(token)),
    );
    return ConversaIaStatus.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<ConversaIaStatus> atualizarConsentimento(String token, bool consentido) async {
    final response = await _request(
      () => _client.put(
        _consentimentoUri,
        headers: _headers(token),
        body: jsonEncode({'consentido': consentido}),
      ),
    );
    return ConversaIaStatus.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() chamada,
  ) async {
    try {
      final response = await chamada().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      var mensagem = 'Não foi possível acessar a conversa.';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['detail'] is String) {
          mensagem = body['detail'] as String;
        }
      } catch (_) {}
      throw ApiError(mensagem, status: response.statusCode);
    } on ApiError {
      rethrow;
    } on Exception {
      throw const ApiError.rede();
    }
  }
}
