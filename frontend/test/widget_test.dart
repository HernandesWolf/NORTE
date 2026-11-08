import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/core/token_storage.dart';
import 'package:norte_app/main.dart';

import 'support/fake_auth_api.dart';

/// Monta o app com um servidor de mentira e armazenamento em memória.
Future<({FakeAuthApi api, MemoryTokenStorage storage})> _abrirApp(
  WidgetTester tester, {
  bool comSessaoSalva = false,
}) async {
  // Tela alta o bastante para o formulário de cadastro caber sem rolagem durante os toques.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = FakeAuthApi();
  final storage = MemoryTokenStorage(comSessaoSalva ? api.criarSessaoValida() : null);
  final auth = AuthController(api: api, storage: storage);

  await tester.pumpWidget(NorteApp(auth: auth));
  await tester.pumpAndSettle();
  return (api: api, storage: storage);
}

Future<void> _preencherEEnviar(WidgetTester tester, {required String email, required String senha}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem sessão salva, mostra a tela de entrada', (tester) async {
    await _abrirApp(tester);

    expect(find.text('Que bom ter você aqui.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('com sessão salva e válida, abre direto o app', (tester) async {
    await _abrirApp(tester, comSessaoSalva: true);

    expect(find.text('Seu espaço'), findsOneWidget);
    expect(find.text('Que bom ter você aqui.'), findsNothing);
  });

  testWidgets('campos vazios: mostra os avisos e não chama o servidor', (tester) async {
    final app = await _abrirApp(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(app.api.chamadasEntrar, 0);
  });

  testWidgets('e-mail inválido é barrado antes de chamar o servidor', (tester) async {
    final app = await _abrirApp(tester);

    await _preencherEEnviar(tester, email: 'isso-nao-e-email', senha: FakeAuthApi.senhaCorreta);

    expect(find.text('E-mail inválido.'), findsOneWidget);
    expect(app.api.chamadasEntrar, 0);
  });

  testWidgets('credenciais corretas abrem o app e guardam a sessão', (tester) async {
    final app = await _abrirApp(tester);

    await _preencherEEnviar(tester, email: 'ana@exemplo.com', senha: FakeAuthApi.senhaCorreta);

    expect(find.text('Seu espaço'), findsOneWidget);
    expect(await app.storage.ler(), isNotNull);
  });

  testWidgets('senha errada mostra a mensagem do servidor e continua na tela de entrada', (tester) async {
    await _abrirApp(tester);

    await _preencherEEnviar(tester, email: 'ana@exemplo.com', senha: 'senha-errada-123');

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(find.text('Que bom ter você aqui.'), findsOneWidget);
  });

  testWidgets('alternar para "criar conta" mostra o campo de nome e exige 8 caracteres', (tester) async {
    final app = await _abrirApp(tester);

    await tester.tap(find.text('Quero criar minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Como podemos chamar você?'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'nova@exemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Criar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('A senha deve ter pelo menos 8 caracteres.'), findsOneWidget);
    expect(app.api.chamadasEntrar, 0);
  });

  testWidgets('e-mail já cadastrado mostra o aviso do servidor uma única vez', (tester) async {
    await _abrirApp(tester);

    await tester.tap(find.text('Quero criar minha conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), FakeAuthApi.emailJaCadastrado);
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), FakeAuthApi.senhaCorreta);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Criar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
  });

  testWidgets('sair da conta volta para a tela de entrada e apaga a sessão', (tester) async {
    final app = await _abrirApp(tester, comSessaoSalva: true);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget); // nome vindo do servidor
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.text('Que bom ter você aqui.'), findsOneWidget);
    expect(await app.storage.ler(), isNull);
  });
}
