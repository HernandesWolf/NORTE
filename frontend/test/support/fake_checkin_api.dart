import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/checkin/checkin_api.dart';
import 'package:norte_app/checkin/checkin_models.dart';

/// Servidor de mentira do check-in: guarda o estado em memória.
class FakeCheckinApi implements CheckinApi {
  FakeCheckinApi({this.atual});

  /// O que o "servidor" tem guardado para hoje.
  EstadoCheckin? atual;

  /// Faz a próxima gravação falhar como se a internet tivesse caído.
  bool falharAoRegistrar = false;

  int chamadasRegistrar = 0;

  @override
  Future<EstadoCheckin?> deHoje(String accessToken) async => atual;

  @override
  Future<EstadoCheckin> registrar(String accessToken, EstadoCheckin estado) async {
    chamadasRegistrar++;
    if (falharAoRegistrar) {
      throw const ApiError.rede();
    }
    atual = estado;
    return estado;
  }
}
