import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/core/token_storage.dart';

import 'support/fake_auth_api.dart';

void main() {
  late FakeAuthApi api;
  late MemoryTokenStorage storage;
  late AuthController auth;

  setUp(() {
    api = FakeAuthApi();
    storage = MemoryTokenStorage();
    auth = AuthController(api: api, storage: storage);
  });

  group('restaurar sessão ao abrir o app', () {
    test('sem sessão salva, fica deslogado', () async {
      await auth.iniciar();

      expect(auth.status, AuthStatus.deslogado);
      expect(auth.usuario, isNull);
    });

    test('com sessão válida salva, entra direto', () async {
      await storage.salvar(api.criarSessaoValida());

      await auth.iniciar();

      expect(auth.status, AuthStatus.logado);
      expect(auth.usuario?.email, 'ana@exemplo.com');
      expect(api.chamadasRenovar, 0);
    });

    test('com acesso expirado mas renovação válida, renova e entra', () async {
      final salva = api.criarSessaoValida();
      await storage.salvar(salva);
      api.accessAceito = 'outro-acesso'; // o acesso guardado "venceu" no servidor

      await auth.iniciar();

      expect(auth.status, AuthStatus.logado);
      expect(api.chamadasRenovar, 1);
      final guardada = await storage.ler();
      expect(guardada?.refreshToken, isNot(salva.refreshToken)); // rotação: o token guardado é o novo
      expect(guardada?.accessToken, api.accessAceito);
    });

    test('com renovação recusada, apaga a sessão e fica deslogado', () async {
      await storage.salvar(api.criarSessaoValida());
      api.accessAceito = 'outro-acesso';
      api.refreshAceito = 'outro-refresh';

      await auth.iniciar();

      expect(auth.status, AuthStatus.deslogado);
      expect(await storage.ler(), isNull);
    });

    test('com servidor fora do ar, não apaga a sessão guardada', () async {
      await storage.salvar(api.criarSessaoValida());
      api.servidorFora = true;

      await auth.iniciar();

      expect(auth.status, AuthStatus.deslogado);
      expect(auth.mensagemErro, isNotNull);
      expect(await storage.ler(), isNotNull); // tenta de novo na próxima abertura
    });

    test('chamar iniciar duas vezes não repete o trabalho', () async {
      await storage.salvar(api.criarSessaoValida());
      api.accessAceito = 'outro-acesso';

      await auth.iniciar();
      await auth.iniciar();

      expect(api.chamadasRenovar, 1);
    });
  });

  group('entrar e cadastrar', () {
    test('entrar com a senha certa guarda a sessão e fica logado', () async {
      final ok = await auth.entrar(email: ' ana@exemplo.com ', senha: FakeAuthApi.senhaCorreta);

      expect(ok, isTrue);
      expect(auth.status, AuthStatus.logado);
      expect(auth.usuario?.nomeOuEmail, 'Ana');
      expect(await storage.ler(), isNotNull);
      expect(auth.ocupado, isFalse);
    });

    test('entrar com a senha errada mostra a mensagem e continua deslogado', () async {
      final ok = await auth.entrar(email: 'ana@exemplo.com', senha: 'errada-qualquer');

      expect(ok, isFalse);
      expect(auth.mensagemErro, 'E-mail ou senha inválidos.');
      expect(await storage.ler(), isNull);
      expect(auth.ocupado, isFalse);
    });

    test('cadastrar com e-mail repetido mostra a mensagem do servidor', () async {
      final ok = await auth.cadastrar(email: FakeAuthApi.emailJaCadastrado, senha: FakeAuthApi.senhaCorreta);

      expect(ok, isFalse);
      expect(auth.mensagemErro, 'Este e-mail já está cadastrado.');
      expect(auth.status, AuthStatus.deslogado);
    });

    test('cadastrar com senha inválida devolve o erro no campo da senha', () async {
      final ok = await auth.cadastrar(email: 'nova@exemplo.com', senha: '123');

      expect(ok, isFalse);
      expect(auth.errosCampos['senha'], 'A senha deve ter entre 8 e 72 caracteres.');
    });

    test('cadastrar com sucesso já deixa a pessoa logada', () async {
      final ok = await auth.cadastrar(nome: 'Ana', email: 'nova@exemplo.com', senha: FakeAuthApi.senhaCorreta);

      expect(ok, isTrue);
      expect(auth.status, AuthStatus.logado);
    });

    test('limparErros zera mensagem e erros de campo', () async {
      await auth.entrar(email: 'ana@exemplo.com', senha: 'errada-qualquer');

      auth.limparErros();

      expect(auth.mensagemErro, isNull);
      expect(auth.errosCampos, isEmpty);
    });
  });

  group('sair', () {
    test('limpa o aparelho e revoga o refresh token no servidor', () async {
      await auth.entrar(email: 'ana@exemplo.com', senha: FakeAuthApi.senhaCorreta);
      final refresh = (await storage.ler())!.refreshToken;

      await auth.sair();

      expect(auth.status, AuthStatus.deslogado);
      expect(auth.usuario, isNull);
      expect(await storage.ler(), isNull);
      expect(api.refreshesRevogados, [refresh]);
    });

    test('sem rede, sai mesmo assim', () async {
      await auth.entrar(email: 'ana@exemplo.com', senha: FakeAuthApi.senhaCorreta);
      api.servidorFora = true;

      await auth.sair();

      expect(auth.status, AuthStatus.deslogado);
      expect(await storage.ler(), isNull);
    });
  });

  group('chamadas autenticadas (comSessao)', () {
    test('pedidos simultâneos com acesso expirado renovam uma única vez', () async {
      await auth.entrar(email: 'ana@exemplo.com', senha: FakeAuthApi.senhaCorreta);
      api.accessAceito = 'acesso-expirado-no-servidor';
      final renovacoesAntes = api.chamadasRenovar;

      // Se cada pedido renovasse por conta própria, o 2º usaria um refresh token já trocado
      // e o servidor real derrubaria a sessão inteira por suspeita de roubo.
      final usuarios = await Future.wait([
        auth.comSessao(api.perfil),
        auth.comSessao(api.perfil),
        auth.comSessao(api.perfil),
      ]);

      expect(usuarios, hasLength(3));
      expect(api.chamadasRenovar - renovacoesAntes, 1);
      expect(auth.status, AuthStatus.logado);
    });

    test('se a renovação for recusada, encerra a sessão e sobe o erro 401', () async {
      await auth.entrar(email: 'ana@exemplo.com', senha: FakeAuthApi.senhaCorreta);
      api.accessAceito = 'acesso-expirado-no-servidor';
      api.refreshAceito = 'refresh-revogado';

      await expectLater(
        auth.comSessao(api.perfil),
        throwsA(isA<Exception>()),
      );

      expect(auth.status, AuthStatus.deslogado);
      expect(await storage.ler(), isNull);
    });

    test('sem sessão, falha com 401 sem chamar o servidor', () async {
      await expectLater(auth.comSessao(api.perfil), throwsA(isA<Exception>()));
    });
  });
}
