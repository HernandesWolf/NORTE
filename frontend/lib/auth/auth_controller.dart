import 'package:flutter/foundation.dart';
import 'package:norte_app/auth/auth_api.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/core/token_storage.dart';

enum AuthStatus { iniciando, deslogado, logado }

/// Cuida da sessão da pessoa: entrar, cadastrar, sair, restaurar a sessão salva e renovar o acesso.
///
/// As telas só "escutam" este objeto (ele é um [ChangeNotifier]) e chamam seus métodos.
class AuthController extends ChangeNotifier {
  AuthController({required AuthApi api, required TokenStorage storage})
      : _api = api,
        _storage = storage;

  final AuthApi _api;
  final TokenStorage _storage;

  AuthStatus _status = AuthStatus.iniciando;
  Usuario? _usuario;
  Sessao? _sessao;
  bool _ocupado = false;
  bool _iniciado = false;
  String? _mensagemErro;
  Map<String, String> _errosCampos = const {};

  /// Renovação em andamento. Com rotação de refresh token, renovar duas vezes com o mesmo token faz o servidor
  /// achar que ele foi roubado e derrubar a sessão. Por isso todos os pedidos esperam a MESMA renovação.
  Future<bool>? _renovacaoEmAndamento;

  AuthStatus get status => _status;
  Usuario? get usuario => _usuario;
  bool get ocupado => _ocupado;
  String? get mensagemErro => _mensagemErro;
  Map<String, String> get errosCampos => _errosCampos;

  /// Restaura a sessão guardada no aparelho (se houver). Seguro de chamar mais de uma vez.
  Future<void> iniciar() async {
    if (_iniciado) {
      return;
    }
    _iniciado = true;

    Sessao? salva;
    try {
      salva = await _storage.ler();
    } catch (_) {
      // Armazenamento ilegível (ex.: dados antigos corrompidos): começamos sem sessão.
      salva = null;
    }
    if (salva == null) {
      _status = AuthStatus.deslogado;
      notifyListeners();
      return;
    }

    _sessao = salva;
    try {
      _usuario = await comSessao(_api.perfil);
      _status = AuthStatus.logado;
      notifyListeners();
    } on ApiError catch (e) {
      if (e.naoAutorizado) {
        await _encerrarLocalmente();
      } else {
        // Sem rede ou servidor fora: não apagamos a sessão, para tentar de novo na próxima abertura.
        _sessao = null;
        _status = AuthStatus.deslogado;
        _mensagemErro = e.mensagem;
        notifyListeners();
      }
    }
  }

  Future<bool> entrar({required String email, required String senha}) {
    return _executar(() async {
      final sessao = await _api.entrar(email: email.trim(), senha: senha);
      await _abrirSessao(sessao);
    });
  }

  Future<bool> cadastrar({required String email, required String senha, String? nome}) {
    return _executar(() async {
      await _api.registrar(email: email.trim(), senha: senha, nome: nome?.trim());
      final sessao = await _api.entrar(email: email.trim(), senha: senha);
      await _abrirSessao(sessao);
    });
  }

  /// Sai da conta. Limpamos o aparelho primeiro: a pessoa não deve ficar presa se a rede falhar.
  Future<void> sair() async {
    final sessao = _sessao;
    await _encerrarLocalmente();
    if (sessao != null) {
      try {
        await _api.sair(sessao.refreshToken);
      } on ApiError {
        // Melhor esforço: sem rede, o token some do aparelho e expira sozinho no servidor.
      }
    }
  }

  void limparErros() {
    if (_mensagemErro == null && _errosCampos.isEmpty) {
      return;
    }
    _mensagemErro = null;
    _errosCampos = const {};
    notifyListeners();
  }

  /// Executa uma chamada autenticada. Se o acesso tiver expirado (401), renova a sessão uma vez e tenta de novo.
  /// Se a renovação for recusada, a sessão é encerrada e o erro 401 sobe para quem chamou.
  ///
  /// Use assim: `auth.comSessao((token) => api.algumaCoisa(token))`.
  Future<T> comSessao<T>(Future<T> Function(String accessToken) chamada) async {
    final atual = _sessao;
    if (atual == null) {
      throw const ApiError('Sessão encerrada. Entre novamente.', status: 401);
    }
    try {
      return await chamada(atual.accessToken);
    } on ApiError catch (e) {
      if (!e.naoAutorizado) {
        rethrow;
      }
    }

    // Outro pedido pode já ter renovado enquanto este falhava: nesse caso basta usar o token novo.
    final depoisDaFalha = _sessao;
    if (depoisDaFalha != null && depoisDaFalha.accessToken != atual.accessToken) {
      return chamada(depoisDaFalha.accessToken);
    }

    final renovou = await _renovar();
    final nova = _sessao;
    if (!renovou || nova == null) {
      throw const ApiError('Sessão expirada. Entre novamente.', status: 401);
    }
    return chamada(nova.accessToken);
  }

  Future<bool> _renovar() {
    return _renovacaoEmAndamento ??=
        _fazerRenovacao().whenComplete(() => _renovacaoEmAndamento = null);
  }

  Future<bool> _fazerRenovacao() async {
    final sessao = _sessao;
    if (sessao == null) {
      return false;
    }
    try {
      final nova = await _api.renovar(sessao.refreshToken);
      await _storage.salvar(nova);
      _sessao = nova;
      return true;
    } on ApiError catch (e) {
      if (!e.naoAutorizado) {
        rethrow; // falha de rede: não é motivo para apagar a sessão
      }
      await _encerrarLocalmente();
      return false;
    }
  }

  Future<bool> _executar(Future<void> Function() acao) async {
    _ocupado = true;
    _mensagemErro = null;
    _errosCampos = const {};
    notifyListeners();
    try {
      await acao();
      return true;
    } on ApiError catch (e) {
      _mensagemErro = e.mensagem;
      _errosCampos = e.erros;
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  Future<void> _abrirSessao(Sessao sessao) async {
    // Buscamos o perfil antes de guardar: só consideramos "logado" quando tudo deu certo.
    final usuario = await _api.perfil(sessao.accessToken);
    await _storage.salvar(sessao);
    _sessao = sessao;
    _usuario = usuario;
    _status = AuthStatus.logado;
  }

  Future<void> _encerrarLocalmente() async {
    _sessao = null;
    _usuario = null;
    _status = AuthStatus.deslogado;
    try {
      await _storage.limpar();
    } catch (_) {
      // Se não deu para limpar agora, a sessão já está desligada na memória; tentamos de novo no próximo logout.
    }
    notifyListeners();
  }
}
