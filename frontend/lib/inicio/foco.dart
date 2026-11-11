import 'package:norte_app/objetivos/objetivos_api.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

/// Situações possíveis do card "Seu foco neste momento".
enum SituacaoFoco {
  /// A pessoa ainda não criou nenhum objetivo.
  semObjetivos,

  /// Todos os objetivos já foram concluídos.
  tudoConcluido,

  /// Há um objetivo em andamento para destacar.
  comFoco,
}

/// O que a tela inicial destaca: o objetivo em andamento e, se houver, o próximo passo do plano dele.
class ResultadoFoco {
  const ResultadoFoco.semObjetivos()
      : situacao = SituacaoFoco.semObjetivos,
        objetivo = null,
        plano = null,
        proximaTarefa = null;

  const ResultadoFoco.tudoConcluido()
      : situacao = SituacaoFoco.tudoConcluido,
        objetivo = null,
        plano = null,
        proximaTarefa = null;

  const ResultadoFoco.comFoco({required Objetivo this.objetivo, required Plano this.plano, this.proximaTarefa})
      : situacao = SituacaoFoco.comFoco;

  final SituacaoFoco situacao;
  final Objetivo? objetivo;
  final Plano? plano;

  /// Primeira tarefa ainda não concluída do plano, ou `null` se não há tarefa pendente.
  final Tarefa? proximaTarefa;
}

/// A primeira tarefa pendente do plano: segue a ordem dos dias (Dia 1 a Dia 7) e, por último, as tarefas sem dia.
Tarefa? proximaTarefaDoPlano(Plano plano) {
  final dias = [...plano.dias]..sort((a, b) => a.dia.compareTo(b.dia));
  for (final dia in dias) {
    for (final tarefa in dia.tarefas) {
      if (!tarefa.concluida) {
        return tarefa;
      }
    }
  }
  for (final tarefa in plano.semDia) {
    if (!tarefa.concluida) {
      return tarefa;
    }
  }
  return null;
}

/// Escolhe o foco da tela inicial.
///
/// Olha os objetivos ainda abertos na ordem em que a lista veio (os mais recentes primeiro) e destaca o primeiro
/// que tem uma tarefa pendente. Se nenhum tem, destaca o primeiro objetivo aberto mesmo assim, para a pessoa
/// ver que falta montar o plano. [limite] evita uma chamada de rede para cada objetivo de uma lista grande.
///
/// Se o plano do primeiro objetivo aberto não puder ser carregado, o erro é repassado. Se falhar só num dos
/// seguintes, ficamos com o que já temos.
Future<ResultadoFoco> calcularFoco({
  required List<Objetivo> objetivos,
  required Future<Plano> Function(String objetivoId) buscarPlano,
  int limite = 5,
}) async {
  if (objetivos.isEmpty) {
    return const ResultadoFoco.semObjetivos();
  }
  final abertos = objetivos.where((o) => !o.concluido).take(limite).toList();
  if (abertos.isEmpty) {
    return const ResultadoFoco.tudoConcluido();
  }

  ResultadoFoco? reserva;
  for (final objetivo in abertos) {
    final Plano plano;
    try {
      plano = await buscarPlano(objetivo.id);
    } on Exception {
      if (reserva == null) {
        rethrow;
      }
      break;
    }
    final proxima = proximaTarefaDoPlano(plano);
    final resultado = ResultadoFoco.comFoco(objetivo: objetivo, plano: plano, proximaTarefa: proxima);
    if (proxima != null) {
      return resultado;
    }
    reserva ??= resultado;
  }
  return reserva!;
}
