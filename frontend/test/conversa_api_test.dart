import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/conversa/conversa_api.dart';

http.Response _json(int status, Object corpo) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(corpo)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

HttpConversaApi _api(MockClientHandler handler) {
  return HttpConversaApi(baseUrl: 'http://api.teste', client: MockClient(handler));
}

Matcher _erroCom(int? status, String mensagem) => throwsA(
      isA<ApiError>().having((e) => e.status, 'status', status).having((e) => e.mensagem, 'mensagem', mensagem),
    );

void main() {
  test('envia a mensagem e o histórico no formato da API e devolve a resposta', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {'resposta': '  Estou aqui.  '});
    });

    final resposta = await api.responder('acesso-abc', 'Não sei por onde começar', const [
      MensagemConversa(papel: PapelConversa.usuario, texto: 'Oi'),
      MensagemConversa(papel: PapelConversa.assistente, texto: 'Olá! O que pesa hoje?'),
    ]);

    expect(resposta, 'Estou aqui.');
    expect(enviada.method, 'POST');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/conversa');
    expect(enviada.headers['Authorization'], 'Bearer acesso-abc');
    final corpo = jsonDecode(enviada.body) as Map<String, dynamic>;
    expect(corpo['mensagem'], 'Não sei por onde começar');
    expect(corpo['historico'], [
      {'papel': 'usuario', 'texto': 'Oi'},
      {'papel': 'assistente', 'texto': 'Olá! O que pesa hoje?'},
    ]);
  });

  test('histórico longo: manda só as 20 mensagens mais recentes', () async {
    late Map<String, dynamic> corpo;
    final api = _api((request) async {
      corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return _json(200, {'resposta': 'ok'});
    });
    final historico = [
      for (var i = 1; i <= 30; i++) MensagemConversa(papel: PapelConversa.usuario, texto: 'mensagem $i'),
    ];

    await api.responder('t', 'agora', historico);

    final enviadas = (corpo['historico'] as List).cast<Map<String, dynamic>>();
    expect(enviadas, hasLength(maxMensagensNoHistorico));
    expect(enviadas.first['texto'], 'mensagem 11');
    expect(enviadas.last['texto'], 'mensagem 30');
  });

  test('textos acima do limite são cortados e mensagens em branco do histórico são descartadas', () async {
    late Map<String, dynamic> corpo;
    final api = _api((request) async {
      corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return _json(200, {'resposta': 'ok'});
    });

    await api.responder('t', 'a' * 5000, [
      MensagemConversa(papel: PapelConversa.assistente, texto: 'b' * 5000),
      const MensagemConversa(papel: PapelConversa.usuario, texto: '   '),
    ]);

    expect((corpo['mensagem'] as String).length, maxCaracteresPorMensagem);
    final historico = (corpo['historico'] as List).cast<Map<String, dynamic>>();
    expect(historico, hasLength(1));
    expect((historico.single['texto'] as String).length, maxCaracteresPorMensagem);
  });

  test('limite de uso (429): mostra a mensagem do servidor', () async {
    final api = _api((_) async => _json(429, {'detail': 'Muitas mensagens em pouco tempo.'}));

    await expectLater(api.responder('t', 'oi', const []), _erroCom(429, 'Muitas mensagens em pouco tempo.'));
  });

  test('IA desligada (503) e fora do ar (502): mostram a mensagem segura do servidor', () async {
    final desligada = _api((_) async => _json(503, {'detail': 'A conversa com IA ainda não está ativada.'}));
    final foraDoAr = _api((_) async => _json(502, {'detail': 'Não consegui falar com a IA agora.'}));

    await expectLater(desligada.responder('t', 'oi', const []), _erroCom(503, 'A conversa com IA ainda não está ativada.'));
    await expectLater(foraDoAr.responder('t', 'oi', const []), _erroCom(502, 'Não consegui falar com a IA agora.'));
  });

  test('erro 500: não mostra o texto vindo do servidor', () async {
    final api = _api((_) async => _json(500, {'detail': 'NullPointerException em Foo.java'}));

    await expectLater(api.responder('t', 'oi', const []), _erroCom(500, 'O servidor teve um problema. Tente novamente em instantes.'));
  });

  test('401 mantém o status, para o app renovar a sessão', () async {
    final api = _api((_) async => http.Response('', 401));

    await expectLater(
      api.responder('t', 'oi', const []),
      throwsA(isA<ApiError>().having((e) => e.naoAutorizado, 'naoAutorizado', isTrue)),
    );
  });

  test('sem internet: vira erro de conexão', () async {
    final api = _api((_) async => throw http.ClientException('sem rede'));

    await expectLater(
      api.responder('t', 'oi', const []),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', isNull)),
    );
  });

  test('resposta sem o campo "resposta": erro amigável', () async {
    final api = _api((_) async => _json(200, {'outra': 'coisa'}));

    await expectLater(api.responder('t', 'oi', const []), _erroCom(null, 'Resposta inesperada do servidor. Tente novamente.'));
  });
}
