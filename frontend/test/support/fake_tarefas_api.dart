import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/tarefas/tarefas_api.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

/// Servidor de mentira das tarefas: guarda tudo em memória e monta o plano como a API real faz.
class FakeTarefasApi implements TarefasApi {
  FakeTarefasApi({List<Tarefa>? iniciais}) : tarefas = [...?iniciais];

  final List<Tarefa> tarefas;

  /// Faz a próxima chamada de [plano] falhar como se a internet tivesse caído.
  bool falharAoCarregar = false;

  int chamadasCriar = 0;
  int _contador = 0;

  @override
  Future<Plano> plano(String accessToken, String objetivoId) async {
    if (falharAoCarregar) {
      throw const ApiError.rede();
    }
    final doObjetivo = tarefas.where((t) => t.objetivoId == objetivoId).toList();
    return Plano(
      objetivoId: objetivoId,
      total: doObjetivo.length,
      concluidas: doObjetivo.where((t) => t.concluida).length,
      dias: [
        for (var dia = 1; dia <= 7; dia++)
          DiaDoPlano(dia: dia, tarefas: doObjetivo.where((t) => t.dia == dia).toList()),
      ],
      semDia: doObjetivo.where((t) => t.dia == null).toList(),
    );
  }

  @override
  Future<Tarefa> criar(String accessToken, String objetivoId, String titulo, int? dia) async {
    chamadasCriar++;
    final nova = Tarefa(id: 'tarefa-${++_contador}', objetivoId: objetivoId, titulo: titulo, dia: dia, concluida: false);
    tarefas.add(nova);
    return nova;
  }

  @override
  Future<Tarefa> atualizar(String accessToken, String id, String titulo, int? dia) async {
    final indice = tarefas.indexWhere((t) => t.id == id);
    final atual = tarefas[indice];
    final nova = Tarefa(id: id, objetivoId: atual.objetivoId, titulo: titulo, dia: dia, concluida: atual.concluida);
    tarefas[indice] = nova;
    return nova;
  }

  @override
  Future<Tarefa> concluir(String accessToken, String id, bool concluida) async {
    final indice = tarefas.indexWhere((t) => t.id == id);
    final atual = tarefas[indice];
    final nova = Tarefa(id: id, objetivoId: atual.objetivoId, titulo: atual.titulo, dia: atual.dia, concluida: concluida);
    tarefas[indice] = nova;
    return nova;
  }

  @override
  Future<void> excluir(String accessToken, String id) async {
    tarefas.removeWhere((t) => t.id == id);
  }
}
