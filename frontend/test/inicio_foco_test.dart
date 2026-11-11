import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/conversa/conversa_page.dart';
import 'package:norte_app/core/token_storage.dart';
import 'package:norte_app/main.dart';
import 'package:norte_app/objetivos/objetivos_api.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

import 'support/fake_auth_api.dart';
import 'support/fake_checkin_api.dart';
import 'support/fake_conversa_api.dart';
import 'support/fake_objetivos_api.dart';
import 'support/fake_tarefas_api.dart';

const _objetivoId = 'obj-1';

Tarefa _tarefa(String id, String titulo, {int? dia, bool concluida = false}) =>
    Tarefa(id: id, objetivoId: _objetivoId, titulo: titulo, dia: dia, concluida: concluida);

const _aprenderJava = Objetivo(id: _objetivoId, titulo: 'Aprender Java', concluido: false);

/// Abre o app já logado, com servidores de mentira de objetivos e tarefas.
Future<void> _abrir(
  WidgetTester tester, {
  required FakeObjetivosApi objetivos,
  required FakeTarefasApi tarefas,
}) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = FakeAuthApi();
  final auth = AuthController(api: api, storage: MemoryTokenStorage(api.criarSessaoValida()));

  await tester.pumpWidget(NorteApp(
    auth: auth,
    checkinApi: FakeCheckinApi(),
    objetivosApi: objetivos,
    tarefasApi: tarefas,
    conversaApi: FakeConversaApi(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem objetivos: convida a criar o primeiro e leva para a aba Objetivos', (tester) async {
    await _abrir(tester, objetivos: FakeObjetivosApi(), tarefas: FakeTarefasApi());

    expect(find.text('Comece com um objetivo pequeno'), findsOneWidget);
    expect(find.text('Seu espaço'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Criar meu primeiro objetivo'));
    await tester.pumpAndSettle();

    expect(find.text('Seus caminhos'), findsOneWidget); // título da aba Objetivos
  });

  testWidgets('com objetivo e tarefas: mostra o objetivo, o próximo passo e o progresso', (tester) async {
    await _abrir(
      tester,
      objetivos: FakeObjetivosApi(objetivos: [_aprenderJava]),
      tarefas: FakeTarefasApi(iniciais: [
        _tarefa('1', 'Instalar o JDK', dia: 1, concluida: true),
        _tarefa('2', 'Ler sobre classes', dia: 2),
      ]),
    );

    expect(find.text('Aprender Java'), findsOneWidget);
    expect(find.text('Ler sobre classes'), findsOneWidget);
    expect(find.text('Dia 2'), findsOneWidget);
    expect(find.text('1 de 2 tarefas'), findsOneWidget);
    expect(find.text('Instalar o JDK'), findsNothing); // essa já está feita
  });

  testWidgets('objetivo sem tarefas: pede um passo pequeno no plano', (tester) async {
    await _abrir(
      tester,
      objetivos: FakeObjetivosApi(objetivos: [_aprenderJava]),
      tarefas: FakeTarefasApi(),
    );

    expect(find.text('Aprender Java'), findsOneWidget);
    expect(find.textContaining('Comece com um passo pequeno'), findsOneWidget);
  });

  testWidgets('tudo concluído: parabeniza e leva para os objetivos', (tester) async {
    await _abrir(
      tester,
      objetivos: FakeObjetivosApi(objetivos: [
        const Objetivo(id: _objetivoId, titulo: 'Aprender Java', concluido: true),
      ]),
      tarefas: FakeTarefasApi(),
    );

    expect(find.text('Você concluiu seus objetivos'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Ver meus objetivos'), findsOneWidget);
  });

  testWidgets('abrir o plano pelo card e voltar atualiza o foco', (tester) async {
    final tarefas = FakeTarefasApi(iniciais: [_tarefa('1', 'Ler sobre classes', dia: 2)]);
    await _abrir(tester, objetivos: FakeObjetivosApi(objetivos: [_aprenderJava]), tarefas: tarefas);

    await tester.tap(find.text('Abrir plano de 7 dias'));
    await tester.pumpAndSettle();
    expect(find.text('Dia 7'), findsOneWidget); // abriu a tela do plano

    // Enquanto a pessoa estava no plano, a tarefa foi concluída.
    await tarefas.concluir('token', '1', true);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.textContaining('Todas as tarefas do plano estão feitas'), findsOneWidget);
    expect(find.text('1 de 1 tarefas'), findsOneWidget);
  });

  testWidgets('se não conseguir carregar, avisa e deixa tentar de novo', (tester) async {
    final objetivos = FakeObjetivosApi(objetivos: [_aprenderJava])..falharAoListar = true;
    await _abrir(
      tester,
      objetivos: objetivos,
      tarefas: FakeTarefasApi(iniciais: [_tarefa('1', 'Ler sobre classes', dia: 2)]),
    );

    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text('Ler sobre classes'), findsNothing);

    objetivos.falharAoListar = false;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.text('Ler sobre classes'), findsOneWidget);
  });

  testWidgets('voltar para a aba Início recalcula o foco', (tester) async {
    final objetivos = FakeObjetivosApi();
    await _abrir(tester, objetivos: objetivos, tarefas: FakeTarefasApi());
    expect(find.text('Comece com um objetivo pequeno'), findsOneWidget);

    // Um objetivo foi criado na aba Objetivos; ao voltar para o Início, o card acompanha.
    objetivos.objetivos.add(_aprenderJava);
    await tester.tap(find.text('Objetivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    expect(find.text('Comece com um objetivo pequeno'), findsNothing);
    expect(find.text('Aprender Java'), findsWidgets);
  });

  testWidgets('"Quer conversar um pouco?" abre a aba Conversa', (tester) async {
    await _abrir(tester, objetivos: FakeObjetivosApi(), tarefas: FakeTarefasApi());
    expect(find.byType(ConversationPage), findsNothing); // aba escondida

    await tester.tap(find.text('Quer conversar um pouco?'));
    await tester.pumpAndSettle();

    expect(find.byType(ConversationPage), findsOneWidget);
  });
}
