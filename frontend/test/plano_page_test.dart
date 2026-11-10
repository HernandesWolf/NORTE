import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/core/token_storage.dart';
import 'package:norte_app/tarefas/plano_page.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

import 'support/fake_auth_api.dart';
import 'support/fake_tarefas_api.dart';

const _objetivoId = 'obj-1';

Tarefa _tarefa(String id, String titulo, {int? dia, bool concluida = false}) =>
    Tarefa(id: id, objetivoId: _objetivoId, titulo: titulo, dia: dia, concluida: concluida);

/// Abre a tela do plano com sessão válida e um servidor de mentira de tarefas.
Future<void> _abrir(WidgetTester tester, FakeTarefasApi tarefas) async {
  // Tela alta o bastante para os 7 dias aparecerem sem rolagem.
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = FakeAuthApi();
  final auth = AuthController(api: api, storage: MemoryTokenStorage(api.criarSessaoValida()));
  await auth.iniciar();

  await tester.pumpWidget(MaterialApp(
    home: PlanoPage(auth: auth, api: tarefas, objetivoId: _objetivoId, objetivoTitulo: 'Aprender Java'),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra o título do objetivo, os 7 dias e as tarefas de cada um', (tester) async {
    await _abrir(
      tester,
      FakeTarefasApi(iniciais: [
        _tarefa('1', 'Instalar o JDK', dia: 1, concluida: true),
        _tarefa('2', 'Ler sobre classes', dia: 2),
        _tarefa('3', 'Rever depois'),
      ]),
    );

    expect(find.text('Aprender Java'), findsOneWidget);
    for (var dia = 1; dia <= 7; dia++) {
      expect(find.text('Dia $dia'), findsOneWidget);
    }
    expect(find.text('Instalar o JDK'), findsOneWidget);
    expect(find.text('Ler sobre classes'), findsOneWidget);
    expect(find.text('Ainda sem dia'), findsOneWidget);
    expect(find.text('Rever depois'), findsOneWidget);
    expect(find.text('1 de 3 concluídas'), findsOneWidget);
  });

  testWidgets('sem tarefas: mostra o convite para começar com um passo pequeno', (tester) async {
    await _abrir(tester, FakeTarefasApi());

    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);
    expect(find.textContaining('Comece com um passo pequeno'), findsOneWidget);
    expect(find.text('Ainda sem dia'), findsNothing);
  });

  testWidgets('criar tarefa pelo "+" de um dia já vem com aquele dia escolhido', (tester) async {
    final servidor = FakeTarefasApi();
    await _abrir(tester, servidor);

    await tester.tap(find.byTooltip('Adicionar tarefa ao dia 2'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dia 2')).selected, isTrue);

    await tester.enterText(find.byType(TextField), '  Praticar 30 minutos  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(servidor.tarefas.single.titulo, 'Praticar 30 minutos');
    expect(servidor.tarefas.single.dia, 2);
    expect(find.text('Praticar 30 minutos'), findsOneWidget);
    expect(find.text('0 de 1 concluídas'), findsOneWidget);
  });

  testWidgets('título em branco mostra o aviso e não chama o servidor', (tester) async {
    final servidor = FakeTarefasApi();
    await _abrir(tester, servidor);

    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o título da tarefa.'), findsOneWidget);
    expect(servidor.chamadasCriar, 0);
  });

  testWidgets('marcar a caixinha conclui a tarefa e atualiza o progresso', (tester) async {
    final servidor = FakeTarefasApi(iniciais: [_tarefa('1', 'Estudar', dia: 1)]);
    await _abrir(tester, servidor);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(servidor.tarefas.single.concluida, isTrue);
    expect(find.text('1 de 1 concluídas'), findsOneWidget);
  });

  testWidgets('editar a tarefa troca o título e o dia', (tester) async {
    final servidor = FakeTarefasApi(iniciais: [_tarefa('1', 'Estudar', dia: 1)]);
    await _abrir(tester, servidor);

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Estudar Spring');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dia 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(servidor.tarefas.single.titulo, 'Estudar Spring');
    expect(servidor.tarefas.single.dia, 4);
  });

  testWidgets('excluir remove a tarefa', (tester) async {
    final servidor = FakeTarefasApi(iniciais: [_tarefa('1', 'Estudar', dia: 1)]);
    await _abrir(tester, servidor);

    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(servidor.tarefas, isEmpty);
    expect(find.text('Estudar'), findsNothing);
    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);
  });

  testWidgets('falha ao abrir mostra o aviso e deixa tentar de novo', (tester) async {
    final servidor = FakeTarefasApi(iniciais: [_tarefa('1', 'Estudar', dia: 1)])..falharAoCarregar = true;
    await _abrir(tester, servidor);

    expect(find.textContaining('Não consegui falar com o servidor'), findsOneWidget);
    expect(find.text('Estudar'), findsNothing);

    servidor.falharAoCarregar = false;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Estudar'), findsOneWidget);
  });
}
