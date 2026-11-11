import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/objetivos/objetivos_api.dart';

/// Servidor de mentira dos objetivos: devolve a lista que o teste preparou, sem internet.
class FakeObjetivosApi extends ObjetivosApi {
  FakeObjetivosApi({List<Objetivo>? objetivos})
      : objetivos = [...?objetivos],
        super(baseUrl: 'http://localhost');

  final List<Objetivo> objetivos;

  /// Faz [listar] falhar como se a internet tivesse caído.
  bool falharAoListar = false;

  @override
  Future<List<Objetivo>> listar(String token) async {
    if (falharAoListar) {
      throw const ApiError.rede();
    }
    return [...objetivos];
  }
}
