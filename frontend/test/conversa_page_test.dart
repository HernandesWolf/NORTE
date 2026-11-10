import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/conversa/conversa_api.dart';
import 'package:norte_app/conversa/conversa_page.dart';
import 'package:norte_app/core/token_storage.dart';

import 'support/fake_auth_api.dart';
import 'support/fake_conversa_api.dart';

/// Abre a aba de conversa com sessão válida e um servidor de mentira.
Future<FakeConversaApi> _abrir(WidgetTester tester, {FakeConversaApi? api}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final fakeAuth = FakeAuthApi();
  final auth = AuthController(api: fakeAuth, storage: MemoryTokenStorage(fakeAuth.criarSessaoValida()));
  await auth.iniciar();

  final conversa = api ?? FakeConversaApi();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ConversationPage(auth: auth, api: conversa)),
  ));
  await tester.pumpAndSettle();
  return conversa;
}

Future<void> _escreverEEnviar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
}

String _textoDoCampo(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('mostra as boas-vindas, o aviso de que é uma IA e as sugestões', (tester) async {
    await _abrir(tester);

    expect(find.textContaining('Estou aqui para ajudar você'), findsOneWidget);
    expect(find.textContaining('inteligência artificial'), findsOneWidget);
    expect(find.text('Quero mudar de carreira'), findsOneWidget);
  });

  testWidgets('enviar: mostra a mensagem e a resposta da IA, e limpa o campo', (tester) async {
    final api = await _abrir(tester, api: FakeConversaApi(resposta: 'Vamos com calma.'));

    await _escreverEEnviar(tester, 'Estou cansada');
    await tester.pumpAndSettle();

    expect(find.text('Estou cansada'), findsOneWidget);
    expect(find.text('Vamos com calma.'), findsOneWidget);
    expect(_textoDoCampo(tester), isEmpty);
    expect(api.chamadas.single.mensagem, 'Estou cansada');
    expect(api.chamadas.single.historico, isEmpty);
  });

  testWidgets('a segunda mensagem leva a conversa anterior como histórico', (tester) async {
    final api = await _abrir(tester, api: FakeConversaApi(resposta: 'Entendi.'));

    await _escreverEEnviar(tester, 'Primeira');
    await tester.pumpAndSettle();
    await _escreverEEnviar(tester, 'Segunda');
    await tester.pumpAndSettle();

    final historico = api.chamadas[1].historico;
    expect(historico.map((m) => m.papel), [PapelConversa.usuario, PapelConversa.assistente]);
    expect(historico.map((m) => m.texto), ['Primeira', 'Entendi.']);
  });

  testWidgets('tocar numa sugestão envia direto e some com as sugestões', (tester) async {
    final api = await _abrir(tester);

    await tester.tap(find.text('Preciso encontrar direção'));
    await tester.pumpAndSettle();

    expect(api.chamadas.single.mensagem, 'Preciso encontrar direção');
    expect(find.text('Você pode começar por:'), findsNothing);
  });

  testWidgets('mensagem em branco não chama o servidor', (tester) async {
    final api = await _abrir(tester);

    await _escreverEEnviar(tester, '   ');
    await tester.pumpAndSettle();

    expect(api.chamadas, isEmpty);
  });

  testWidgets('enquanto a IA pensa: mostra o aviso e não deixa enviar de novo', (tester) async {
    final api = await _abrir(tester, api: FakeConversaApi()..pendente = Completer<String>());

    await _escreverEEnviar(tester, 'Oi');
    await tester.pump();

    expect(find.text('NORTE está pensando…'), findsOneWidget);
    final botao = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded));
    expect(botao.onPressed, isNull);

    api.pendente!.complete('Olá!');
    await tester.pumpAndSettle();

    expect(find.text('NORTE está pensando…'), findsNothing);
    expect(find.text('Olá!'), findsOneWidget);
  });

  testWidgets('se falhar: avisa, tira a mensagem da conversa e devolve o texto ao campo', (tester) async {
    final api = await _abrir(
      tester,
      api: FakeConversaApi()..falha = const ApiError('Muitas mensagens em pouco tempo.', status: 429),
    );

    await _escreverEEnviar(tester, 'Preciso de ajuda');
    // Sem pumpAndSettle: ele esperaria o aviso sumir sozinho e o teste não o encontraria mais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Muitas mensagens em pouco tempo.'), findsOneWidget);
    expect(_textoDoCampo(tester), 'Preciso de ajuda');
    expect(api.chamadas, hasLength(1));
    expect(find.text('NORTE está pensando…'), findsNothing);
  });
}
