import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norte_app/auth/auth_api.dart';
import 'package:norte_app/auth/auth_models.dart';

/// Resposta JSON em UTF-8, como o Spring devolve (importante para acentos nas mensagens).
http.Response _json(int status, Object corpo, {String tipo = 'application/json'}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(corpo)),
    status,
    headers: {'content-type': tipo},
  );
}

HttpAuthApi _api(MockClientHandler handler) {
  return HttpAuthApi(baseUrl: 'http://api.teste', client: MockClient(handler));
}

void main() {
  test('entrar: lê o par de tokens e envia e-mail e senha em JSON', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {
        'accessToken': 'acesso-abc',
        'refreshToken': 'refresh-xyz',
        'tipo': 'Bearer',
        'expiraEmSegundos': 900,
      });
    });

    final sessao = await api.entrar(email: 'ana@exemplo.com', senha: 'senhaforte123');

    expect(sessao.accessToken, 'acesso-abc');
    expect(sessao.refreshToken, 'refresh-xyz');
    expect(enviada.method, 'POST');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/auth/login');
    expect(jsonDecode(enviada.body), {'email': 'ana@exemplo.com', 'senha': 'senhaforte123'});
  });

  test('entrar: 401 vira ApiError com a mensagem do servidor (acentos preservados)', () async {
    final api = _api((request) async => _json(
          401,
          {'status': 401, 'detail': 'E-mail ou senha inválidos.'},
          tipo: 'application/problem+json',
        ));

    await expectLater(
      api.entrar(email: 'ana@exemplo.com', senha: 'errada'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.mensagem, 'mensagem', 'E-mail ou senha inválidos.')
            .having((e) => e.naoAutorizado, 'naoAutorizado', isTrue),
      ),
    );
  });

  test('registrar: 400 traz os erros por campo', () async {
    final api = _api((request) async => _json(400, {
          'detail': 'Dados inválidos.',
          'erros': {'senha': 'A senha deve ter entre 8 e 72 caracteres.'},
        }));

    await expectLater(
      api.registrar(email: 'ana@exemplo.com', senha: '123'),
      throwsA(isA<ApiError>().having(
        (e) => e.erros['senha'],
        'erro do campo senha',
        'A senha deve ter entre 8 e 72 caracteres.',
      )),
    );
  });

  test('registrar: só envia nomeExibicao quando há nome', () async {
    final corpos = <Map<String, dynamic>>[];
    final api = _api((request) async {
      corpos.add(jsonDecode(request.body) as Map<String, dynamic>);
      return _json(201, {'id': 'id-1', 'email': 'ana@exemplo.com', 'nomeExibicao': null});
    });

    await api.registrar(email: 'ana@exemplo.com', senha: 'senhaforte123');
    await api.registrar(email: 'ana@exemplo.com', senha: 'senhaforte123', nome: 'Ana');

    expect(corpos[0].containsKey('nomeExibicao'), isFalse);
    expect(corpos[1]['nomeExibicao'], 'Ana');
  });

  test('429: mostra a mensagem do servidor (muitas tentativas)', () async {
    final api = _api((request) async => _json(429, {'detail': 'Muitas tentativas de entrada. Aguarde.'}));

    await expectLater(
      api.entrar(email: 'ana@exemplo.com', senha: 'x'),
      throwsA(isA<ApiError>()
          .having((e) => e.status, 'status', 429)
          .having((e) => e.mensagem, 'mensagem', contains('Muitas tentativas'))),
    );
  });

  test('erro 500 usa mensagem genérica, sem vazar detalhes internos', () async {
    final api = _api((request) async => _json(500, {'detail': 'NullPointerException em AuthService:42'}));

    await expectLater(
      api.perfil('acesso'),
      throwsA(isA<ApiError>().having((e) => e.mensagem, 'mensagem', isNot(contains('NullPointer')))),
    );
  });

  test('sem conexão: vira ApiError.rede (sem status)', () async {
    final api = _api((request) async => throw http.ClientException('sem internet'));

    await expectLater(
      api.entrar(email: 'ana@exemplo.com', senha: 'x'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', isNull)),
    );
  });

  test('perfil: envia o token no cabeçalho Authorization', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {'id': 'id-1', 'email': 'ana@exemplo.com', 'nomeExibicao': 'Ana'});
    });

    final usuario = await api.perfil('meu-acesso');

    expect(enviada.headers['Authorization'], 'Bearer meu-acesso');
    expect(enviada.url.path, '/api/v1/me');
    expect(usuario.nomeExibicao, 'Ana');
  });

  test('renovar e sair: enviam o refresh token no corpo', () async {
    final recebidos = <String, Object?>{};
    final api = _api((request) async {
      recebidos[request.url.path] = jsonDecode(request.body);
      if (request.url.path.endsWith('/logout')) {
        return http.Response('', 204);
      }
      return _json(200, {'accessToken': 'a2', 'refreshToken': 'r2', 'tipo': 'Bearer'});
    });

    final nova = await api.renovar('r1');
    await api.sair('r2');

    expect(nova.refreshToken, 'r2');
    expect(recebidos['/api/v1/auth/refresh'], {'refreshToken': 'r1'});
    expect(recebidos['/api/v1/auth/logout'], {'refreshToken': 'r2'});
  });

  test('resposta 200 sem os tokens esperados vira erro claro', () async {
    final api = _api((request) async => _json(200, {'qualquer': 'coisa'}));

    await expectLater(
      api.entrar(email: 'ana@exemplo.com', senha: 'x'),
      throwsA(isA<ApiError>()),
    );
  });

  test('Usuario.nomeOuEmail cai para o e-mail quando não há nome', () {
    expect(const Usuario(id: '1', email: 'a@b.com').nomeOuEmail, 'a@b.com');
    expect(const Usuario(id: '1', email: 'a@b.com', nomeExibicao: '  ').nomeOuEmail, 'a@b.com');
    expect(const Usuario(id: '1', email: 'a@b.com', nomeExibicao: 'Ana').nomeOuEmail, 'Ana');
  });
}
