import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/checkin/checkin_api.dart';
import 'package:norte_app/checkin/checkin_models.dart';

http.Response _json(int status, Object corpo) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(corpo)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

HttpCheckinApi _api(MockClientHandler handler) {
  return HttpCheckinApi(baseUrl: 'http://api.teste', client: MockClient(handler));
}

void main() {
  test('deHoje: lê o estado e envia o token no cabeçalho', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {'estado': 'INDO_DEVAGAR', 'dia': '2026-11-07', 'atualizadoEm': '2026-11-07T20:00:00Z'});
    });

    final estado = await api.deHoje('acesso-abc');

    expect(estado, EstadoCheckin.indoDevagar);
    expect(enviada.method, 'GET');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/checkins/hoje');
    expect(enviada.headers['Authorization'], 'Bearer acesso-abc');
  });

  test('deHoje: 204 significa que ainda não houve check-in hoje', () async {
    final api = _api((request) async => http.Response('', 204));

    expect(await api.deHoje('acesso-abc'), isNull);
  });

  test('registrar: envia o código do estado em JSON com PUT', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {'estado': 'SOBRECARREGADO', 'dia': '2026-11-07', 'atualizadoEm': '2026-11-07T20:00:00Z'});
    });

    final estado = await api.registrar('acesso-abc', EstadoCheckin.sobrecarregado);

    expect(estado, EstadoCheckin.sobrecarregado);
    expect(enviada.method, 'PUT');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/checkins/hoje');
    expect(jsonDecode(enviada.body), {'estado': 'SOBRECARREGADO'});
    expect(enviada.headers['Authorization'], 'Bearer acesso-abc');
    expect(enviada.headers['Content-Type'], contains('application/json'));
  });

  test('401 vira ApiError.naoAutorizado, para o app tentar renovar a sessão', () async {
    final api = _api((request) async => _json(401, {'detail': 'Sessão inválida ou expirada.'}));

    await expectLater(
      api.deHoje('acesso-vencido'),
      throwsA(isA<ApiError>().having((e) => e.naoAutorizado, 'naoAutorizado', isTrue)),
    );
  });

  test('erro 400 mostra a mensagem do servidor (com acentos)', () async {
    final api = _api((request) async => _json(400, {'detail': 'Corpo da requisição inválido.'}));

    await expectLater(
      api.registrar('acesso-abc', EstadoCheckin.comEnergia),
      throwsA(isA<ApiError>().having((e) => e.mensagem, 'mensagem', 'Corpo da requisição inválido.')),
    );
  });

  test('estado desconhecido na resposta vira erro, não quebra o app', () async {
    final api = _api((request) async => _json(200, {'estado': 'ALGO_NOVO'}));

    await expectLater(api.deHoje('acesso-abc'), throwsA(isA<ApiError>()));
  });

  test('falha de rede vira ApiError.rede', () async {
    final api = _api((request) async => throw http.ClientException('sem internet'));

    await expectLater(
      api.deHoje('acesso-abc'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', isNull)),
    );
  });
}
