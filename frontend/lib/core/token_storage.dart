import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par de tokens de uma sessão. O [accessToken] é curto (vai em cada requisição);
/// o [refreshToken] é longo e só serve para renovar o acesso.
class Sessao {
  const Sessao({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Onde a sessão fica guardada entre uma abertura e outra do app.
abstract class TokenStorage {
  Future<Sessao?> ler();
  Future<void> salvar(Sessao sessao);
  Future<void> limpar();
}

/// Armazenamento seguro de verdade: Keychain (iOS), Keystore (Android) e equivalentes nos outros sistemas.
///
/// Atenção no Flutter Web: o navegador não tem um cofre equivalente. O pacote cifra os valores, mas a chave
/// também fica no navegador, então a proteção é bem mais fraca. Serve para desenvolvimento e demonstração;
/// antes de um piloto web, vale rever essa decisão.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _chaveAcesso = 'norte_access_token';
  static const _chaveRenovacao = 'norte_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<Sessao?> ler() async {
    final acesso = await _storage.read(key: _chaveAcesso);
    final renovacao = await _storage.read(key: _chaveRenovacao);
    if (acesso == null || renovacao == null) {
      return null;
    }
    return Sessao(accessToken: acesso, refreshToken: renovacao);
  }

  @override
  Future<void> salvar(Sessao sessao) async {
    await _storage.write(key: _chaveAcesso, value: sessao.accessToken);
    await _storage.write(key: _chaveRenovacao, value: sessao.refreshToken);
  }

  @override
  Future<void> limpar() async {
    await _storage.delete(key: _chaveAcesso);
    await _storage.delete(key: _chaveRenovacao);
  }
}

/// Guarda a sessão só na memória (some quando o app fecha). Usado nos testes.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this._sessao]);

  Sessao? _sessao;

  @override
  Future<Sessao?> ler() async => _sessao;

  @override
  Future<void> salvar(Sessao sessao) async => _sessao = sessao;

  @override
  Future<void> limpar() async => _sessao = null;
}
