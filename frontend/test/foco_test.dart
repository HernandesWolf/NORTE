import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/inicio/foco.dart';
import 'package:norte_app/objetivos/objetivos_api.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

import 'support/fake_tarefas_api.dart';

Objetivo _objetivo(String id, {bool concluido = false}) =>
    Objetivo(id: id, titulo: 'Objetivo $id', concluido: concluido);

Tarefa _tarefa(String id, String objetivoId, {int? dia, bool concluida = false}) =>
    Tarefa(id: id, objetivoId: objetivoId, titulo: 'Tarefa $id', dia: dia, concluida: concluida);

/// Plano montado pelo servidor de mentira, do mesmo jeito que a API real faz.
Future<Plano> _plano(List<Tarefa> tarefas, String objetivoId) =>
    FakeTarefasApi(iniciais: tarefas).plano('token', objetivoId);

void main() {
  group('proximaTarefaDoPlano', () {
    test('segue a ordem dos dias e pula as tarefas concluídas', () async {
      final plano = await _plano([
        _tarefa('a', 'o1', dia: 1, concluida: true),
        _tarefa('b', 'o1', dia: 3),
        _tarefa('c', 'o1', dia: 2),
      ], 'o1');

      expect(proximaTarefaDoPlano(plano)?.id, 'c');
    });

    test('deixa as tarefas sem dia para depois das que têm dia', () async {
      final plano = await _plano([
        _tarefa('sem-dia', 'o1'),
        _tarefa('dia-7', 'o1', dia: 7),
      ], 'o1');

      expect(proximaTarefaDoPlano(plano)?.id, 'dia-7');
    });

    test('usa uma tarefa sem dia quando é a única pendente', () async {
      final plano = await _plano([
        _tarefa('feita', 'o1', dia: 1, concluida: true),
        _tarefa('sem-dia', 'o1'),
      ], 'o1');

      expect(proximaTarefaDoPlano(plano)?.id, 'sem-dia');
    });

    test('devolve nulo quando não há tarefa pendente', () async {
      final vazio = await _plano([], 'o1');
      final tudoFeito = await _plano([_tarefa('a', 'o1', dia: 1, concluida: true)], 'o1');

      expect(proximaTarefaDoPlano(vazio), isNull);
      expect(proximaTarefaDoPlano(tudoFeito), isNull);
    });
  });

  group('calcularFoco', () {
    test('sem objetivos, convida a criar o primeiro', () async {
      final foco = await calcularFoco(
        objetivos: [],
        buscarPlano: (_) => throw StateError('não deveria buscar plano'),
      );

      expect(foco.situacao, SituacaoFoco.semObjetivos);
    });

    test('com todos os objetivos concluídos, avisa que está tudo feito', () async {
      final foco = await calcularFoco(
        objetivos: [_objetivo('o1', concluido: true), _objetivo('o2', concluido: true)],
        buscarPlano: (_) => throw StateError('não deveria buscar plano'),
      );

      expect(foco.situacao, SituacaoFoco.tudoConcluido);
    });

    test('destaca o primeiro objetivo aberto que tem tarefa pendente', () async {
      final tarefas = [
        _tarefa('t1', 'o1', dia: 1, concluida: true), // o1 está todo feito
        _tarefa('t2', 'o2', dia: 2),
      ];
      final consultados = <String>[];

      final foco = await calcularFoco(
        objetivos: [_objetivo('o1'), _objetivo('o2'), _objetivo('o3')],
        buscarPlano: (id) {
          consultados.add(id);
          return _plano(tarefas, id);
        },
      );

      expect(foco.situacao, SituacaoFoco.comFoco);
      expect(foco.objetivo?.id, 'o2');
      expect(foco.proximaTarefa?.id, 't2');
      expect(consultados, ['o1', 'o2']); // parou assim que achou; não consultou o3
    });

    test('ignora os objetivos já concluídos', () async {
      final foco = await calcularFoco(
        objetivos: [_objetivo('o1', concluido: true), _objetivo('o2')],
        buscarPlano: (id) => _plano([_tarefa('t', id, dia: 1)], id),
      );

      expect(foco.objetivo?.id, 'o2');
    });

    test('sem nenhuma tarefa pendente, destaca o primeiro objetivo aberto mesmo assim', () async {
      final foco = await calcularFoco(
        objetivos: [_objetivo('o1'), _objetivo('o2')],
        buscarPlano: (id) => _plano([], id),
      );

      expect(foco.situacao, SituacaoFoco.comFoco);
      expect(foco.objetivo?.id, 'o1');
      expect(foco.proximaTarefa, isNull);
      expect(foco.plano?.total, 0);
    });

    test('respeita o limite de objetivos consultados', () async {
      var consultas = 0;

      await calcularFoco(
        objetivos: [for (var i = 1; i <= 8; i++) _objetivo('o$i')],
        buscarPlano: (id) {
          consultas++;
          return _plano([], id);
        },
        limite: 3,
      );

      expect(consultas, 3);
    });

    test('se o plano do primeiro objetivo falhar, repassa o erro', () async {
      final chamada = calcularFoco(
        objetivos: [_objetivo('o1')],
        buscarPlano: (_) => throw const ApiError.rede(),
      );

      await expectLater(chamada, throwsA(isA<ApiError>()));
    });

    test('se falhar só num objetivo seguinte, fica com o que já tinha', () async {
      final foco = await calcularFoco(
        objetivos: [_objetivo('o1'), _objetivo('o2')],
        buscarPlano: (id) {
          if (id == 'o2') {
            throw const ApiError.rede();
          }
          return _plano([], id);
        },
      );

      expect(foco.objetivo?.id, 'o1');
    });
  });
}
