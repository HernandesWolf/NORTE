/// Uma tarefa de um objetivo. [dia] é o dia do plano de 7 dias (1 a 7), ou `null` se ainda não tem dia.
class Tarefa {
  const Tarefa({
    required this.id,
    required this.objetivoId,
    required this.titulo,
    required this.concluida,
    this.dia,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
        id: json['id'] as String,
        objetivoId: json['objetivoId'] as String,
        titulo: json['titulo'] as String,
        dia: json['dia'] as int?,
        concluida: json['concluida'] as bool? ?? false,
      );

  final String id;
  final String objetivoId;
  final String titulo;
  final int? dia;
  final bool concluida;
}

/// As tarefas de um dia do plano.
class DiaDoPlano {
  const DiaDoPlano({required this.dia, required this.tarefas});

  factory DiaDoPlano.fromJson(Map<String, dynamic> json) => DiaDoPlano(
        dia: json['dia'] as int,
        tarefas: _tarefasDe(json['tarefas']),
      );

  final int dia;
  final List<Tarefa> tarefas;
}

/// Plano de 7 dias de um objetivo: sempre traz os 7 dias (mesmo vazios) e as tarefas que ainda não têm dia.
class Plano {
  const Plano({
    required this.objetivoId,
    required this.total,
    required this.concluidas,
    required this.dias,
    required this.semDia,
  });

  factory Plano.fromJson(Map<String, dynamic> json) => Plano(
        objetivoId: json['objetivoId'] as String,
        total: json['total'] as int,
        concluidas: json['concluidas'] as int,
        dias: (json['dias'] as List)
            .map((item) => DiaDoPlano.fromJson(item as Map<String, dynamic>))
            .toList(),
        semDia: _tarefasDe(json['semDia']),
      );

  final String objetivoId;
  final int total;
  final int concluidas;
  final List<DiaDoPlano> dias;
  final List<Tarefa> semDia;

  /// De 0 a 1, para a barra de progresso.
  double get progresso => total == 0 ? 0 : concluidas / total;
}

List<Tarefa> _tarefasDe(Object? json) =>
    (json as List).map((item) => Tarefa.fromJson(item as Map<String, dynamic>)).toList();
