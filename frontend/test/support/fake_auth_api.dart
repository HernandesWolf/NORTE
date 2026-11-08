import 'package:norte_app/auth/auth_api.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/core/token_storage.dart';

/// Servidor de mentira para os testes: sabe qual access/refresh token considera válido agora,
/// como o servidor real, e recusa (401) todo o resto.
class FakeAuthApi implements AuthApi {
  static const senhaCorreta = 'senhaforte123';
  static const emailJaCadastrado = 'repetido@exemplo.com';

  final usuario = const Usuario(id: 'id-1', email: 'ana@exemplo.com', nomeExibicao: 'Ana');

  /// Tokens que o "servidor" aceita neste momento.
  String? accessAceito;
  String? refreshAceito;

  /// Simula servidor desligado ou sem internet.
  bool servidorFora = false;

  int chamadasEntrar = 0;
  int chamadasRenovar = 0;
  final refreshesRevogados = <String>[];

  int _contador = 100;

  /// Pré-configura o servidor como se esta sessão já existisse (útil para "reabrir o app").
  Sessao criarSessaoValida() => _novaSessao();

  Sessao _novaSessao() {
    _contador++;
    accessAceito = 'acesso-$_contador';
    refreshAceito = 'refresh-$_contador';
    return Sessao(accessToken: accessAceito!, refreshToken: refreshAceito!);
  }

  void _exigirRede() {
    if (servidorFora) {
      throw const ApiError.rede();
    }
  }

  @override
  Future<Usuario> registrar({required String email, required String senha, String? nome}) async {
    _exigirRede();
    // Como o servidor real: validação de campos devolve 400 com o mapa "erros"...
    if (senha.length < 8) {
      throw const ApiError(
        'Dados inválidos.',
        status: 400,
        erros: {'senha': 'A senha deve ter entre 8 e 72 caracteres.'},
      );
    }
    // ...e e-mail repetido devolve 409 só com a mensagem (sem mapa de erros).
    if (email == emailJaCadastrado) {
      throw const ApiError('Este e-mail já está cadastrado.', status: 409);
    }
    return usuario;
  }

  @override
  Future<Sessao> entrar({required String email, required String senha}) async {
    chamadasEntrar++;
    _exigirRede();
    if (senha != senhaCorreta) {
      throw const ApiError('E-mail ou senha inválidos.', status: 401);
    }
    return _novaSessao();
  }

  @override
  Future<Sessao> renovar(String refreshToken) async {
    chamadasRenovar++;
    _exigirRede();
    if (refreshToken != refreshAceito) {
      throw const ApiError('Sessão inválida ou expirada. Entre novamente.', status: 401);
    }
    return _novaSessao();
  }

  @override
  Future<void> sair(String refreshToken) async {
    _exigirRede();
    refreshesRevogados.add(refreshToken);
    if (refreshToken == refreshAceito) {
      refreshAceito = null;
    }
  }

  @override
  Future<Usuario> perfil(String accessToken) async {
    _exigirRede();
    if (accessToken != accessAceito) {
      throw const ApiError('Sessão inválida.', status: 401);
    }
    return usuario;
  }
}
