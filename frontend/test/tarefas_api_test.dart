import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/tarefas/tarefas_api.dart';

http.Response _json(int status, Object corpo) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(corpo)),
    status,
    headers: {'content-type': 'application/json'},
  );
}

HttpTarefasApi _api(MockClientHandler handler) {
  return HttpTarefasApi(baseUrl: 'http://api.teste', client: MockClient(handler));
}

Map<String, Object?> _tarefa({String id = 't-1', String titulo = 'Estudar', int? dia = 1, bool concluida = false}) => {
      'id': id,
      'objetivoId': 'obj-1',
      'titulo': titulo,
      'dia': dia,
      'concluida': concluida,
      'criadoEm': '2026-11-10T12:00:00Z',
      'atualizadoEm': '2026-11-10T12:00:00Z',
    };

void main() {
  test('plano: lê os 7 dias, as tarefas sem dia e o progresso', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, {
        'objetivoId': 'obj-1',
        'total': 2,
        'concluidas': 1,
        'dias': [
          for (var dia = 1; dia <= 7; dia++)
            {
              'dia': dia,
              'tarefas': dia == 1 ? [_tarefa(concluida: true)] : <Object>[],
            },
        ],
        'semDia': [_tarefa(id: 't-2', titulo: 'Ler', dia: null)],
      });
    });

    final plano = await api.plano('acesso-abc', 'obj-1');

    expect(enviada.method, 'GET');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/objetivos/obj-1/plano');
    expect(enviada.headers['Authorization'], 'Bearer acesso-abc');
    expect(plano.dias, hasLength(7));
    expect(plano.dias.first.tarefas.single.titulo, 'Estudar');
    expect(plano.dias.first.tarefas.single.concluida, isTrue);
    expect(plano.semDia.single.titulo, 'Ler');
    expect(plano.semDia.single.dia, isNull);
    expect(plano.total, 2);
    expect(plano.progresso, 0.5);
  });

  test('plano: sem tarefas, o progresso é zero (sem dividir por zero)', () async {
    final api = _api((request) async => _json(200, {
          'objetivoId': 'obj-1',
          'total': 0,
          'concluidas': 0,
          'dias': <Object>[],
          'semDia': <Object>[],
        }));

    final plano = await api.plano('acesso-abc', 'obj-1');

    expect(plano.progresso, 0);
  });

  test('criar: envia título e dia em JSON com POST no objetivo', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(201, _tarefa(dia: 3));
    });

    final tarefa = await api.criar('acesso-abc', 'obj-1', 'Estudar', 3);

    expect(tarefa.dia, 3);
    expect(enviada.method, 'POST');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/objetivos/obj-1/tarefas');
    expect(jsonDecode(enviada.body), {'titulo': 'Estudar', 'dia': 3});
    expect(enviada.headers['Content-Type'], contains('application/json'));
  });

  test('criar: sem dia envia dia nulo', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(201, _tarefa(dia: null));
    });

    final tarefa = await api.criar('acesso-abc', 'obj-1', 'Ler', null);

    expect(tarefa.dia, isNull);
    expect(jsonDecode(enviada.body), {'titulo': 'Ler', 'dia': null});
  });

  test('atualizar: PUT na tarefa com título e dia', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, _tarefa(titulo: 'Novo', dia: 5));
    });

    final tarefa = await api.atualizar('acesso-abc', 't-1', 'Novo', 5);

    expect(tarefa.titulo, 'Novo');
    expect(enviada.method, 'PUT');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/tarefas/t-1');
    expect(jsonDecode(enviada.body), {'titulo': 'Novo', 'dia': 5});
  });

  test('concluir: PATCH em /conclusao com o campo "concluida"', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return _json(200, _tarefa(concluida: true));
    });

    final tarefa = await api.concluir('acesso-abc', 't-1', true);

    expect(tarefa.concluida, isTrue);
    expect(enviada.method, 'PATCH');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/tarefas/t-1/conclusao');
    expect(jsonDecode(enviada.body), {'concluida': true});
  });

  test('excluir: DELETE na tarefa e aceita 204', () async {
    late http.Request enviada;
    final api = _api((request) async {
      enviada = request;
      return http.Response('', 204);
    });

    await api.excluir('acesso-abc', 't-1');

    expect(enviada.method, 'DELETE');
    expect(enviada.url.toString(), 'http://api.teste/api/v1/tarefas/t-1');
    expect(enviada.headers['Authorization'], 'Bearer acesso-abc');
  });

  test('erro da API: mostra a mensagem do servidor e guarda o status', () async {
    final api = _api((request) async => _json(404, {'detail': 'Objetivo não encontrado.'}));

    await expectLater(
      api.plano('acesso-abc', 'obj-1'),
      throwsA(isA<ApiError>()
          .having((e) => e.mensagem, 'mensagem', 'Objetivo não encontrado.')
          .having((e) => e.status, 'status', 404)),
    );
  });

  test('erro 401 é reconhecido como não autorizado (para renovar a sessão)', () async {
    final api = _api((request) async => _json(401, {'detail': 'Sessão inválida.'}));

    await expectLater(
      api.plano('acesso-abc', 'obj-1'),
      throwsA(isA<ApiError>().having((e) => e.naoAutorizado, 'naoAutorizado', isTrue)),
    );
  });

  test('erro 500 não vaza detalhe do servidor', () async {
    final api = _api((request) async => _json(500, {'detail': 'NullPointerException em TarefaService'}));

    await expectLater(
      api.plano('acesso-abc', 'obj-1'),
      throwsA(isA<ApiError>().having((e) => e.mensagem, 'mensagem', isNot(contains('NullPointer')))),
    );
  });

  test('sem internet vira erro de conexão', () async {
    final api = _api((request) async => throw http.ClientException('sem rede'));

    await expectLater(
      api.plano('acesso-abc', 'obj-1'),
      throwsA(isA<ApiError>().having((e) => e.status, 'status', isNull)),
    );
  });

  test('resposta fora do formato esperado vira erro amigável', () async {
    final api = _api((request) async => _json(200, {'inesperado': true}));

    await expectLater(
      api.plano('acesso-abc', 'obj-1'),
      throwsA(isA<ApiError>().having((e) => e.mensagem, 'mensagem', contains('Resposta inesperada'))),
    );
  });
}
