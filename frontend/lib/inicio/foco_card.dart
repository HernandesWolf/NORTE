import 'package:flutter/material.dart';
import 'package:norte_app/core/norte_colors.dart';
import 'package:norte_app/inicio/foco.dart';

/// Card "Seu foco neste momento": mostra o objetivo em andamento e o próximo passo, ou convida a começar.
class FocoCard extends StatelessWidget {
  const FocoCard({
    required this.carregando,
    required this.onAbrirPlano,
    required this.onAbrirObjetivos,
    required this.onTentarDeNovo,
    this.resultado,
    this.erro,
    super.key,
  });

  final bool carregando;
  final ResultadoFoco? resultado;
  final String? erro;

  /// Abre o plano de 7 dias do objetivo em foco.
  final VoidCallback onAbrirPlano;

  /// Leva para a aba de objetivos.
  final VoidCallback onAbrirObjetivos;
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _conteudo(),
      ),
    );
  }

  Widget _conteudo() {
    final atual = resultado;
    if (atual != null) {
      return switch (atual.situacao) {
        SituacaoFoco.semObjetivos => _convite(
            titulo: 'Comece com um objetivo pequeno',
            texto: 'Escolha algo que caiba na sua realidade. Depois a gente divide em passos.',
            botao: 'Criar meu primeiro objetivo',
          ),
        SituacaoFoco.tudoConcluido => _convite(
            titulo: 'Você concluiu seus objetivos',
            texto: 'Que bom chegar até aqui. Quando quiser, comece um novo caminho.',
            botao: 'Ver meus objetivos',
          ),
        SituacaoFoco.comFoco => _comFoco(atual),
      };
    }
    if (erro != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(erro!, style: const TextStyle(color: Color(0xFF9B3D4A), fontSize: 13, height: 1.4)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onTentarDeNovo,
          style: TextButton.styleFrom(foregroundColor: NorteColors.wine),
          child: const Text('Tentar de novo'),
        ),
      ]);
    }
    if (carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _convite({required String titulo, required String texto, required String botao}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.flag_outlined, color: NorteColors.rose),
        SizedBox(width: 9),
        Text('Um caminho para começar', style: TextStyle(fontWeight: FontWeight.w700, color: NorteColors.ink)),
      ]),
      const SizedBox(height: 12),
      Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(texto, style: const TextStyle(color: NorteColors.muted, fontSize: 13, height: 1.4)),
      const SizedBox(height: 14),
      ElevatedButton(onPressed: onAbrirObjetivos, child: Text(botao)),
    ]);
  }

  Widget _comFoco(ResultadoFoco foco) {
    final objetivo = foco.objetivo!;
    final plano = foco.plano!;
    final proxima = foco.proximaTarefa;
    final dia = proxima?.dia;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.flag_outlined, color: NorteColors.rose),
        SizedBox(width: 9),
        Text('Seu caminho agora', style: TextStyle(fontWeight: FontWeight.w700, color: NorteColors.ink)),
      ]),
      const SizedBox(height: 12),
      Text(objetivo.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3)),
      const SizedBox(height: 10),
      if (proxima != null) ...[
        const Text('PRÓXIMO PASSO', style: TextStyle(color: NorteColors.wine, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(proxima.titulo, style: const TextStyle(fontSize: 15, height: 1.35)),
        const SizedBox(height: 2),
        Text(dia == null ? 'Sem dia definido' : 'Dia $dia', style: const TextStyle(color: NorteColors.muted, fontSize: 12)),
      ] else if (plano.total == 0)
        const Text('Ainda sem tarefas. Comece com um passo pequeno no plano de 7 dias.', style: TextStyle(color: NorteColors.muted, fontSize: 13, height: 1.4))
      else
        const Text('Todas as tarefas do plano estão feitas. Bom trabalho!', style: TextStyle(color: NorteColors.muted, fontSize: 13, height: 1.4)),
      if (plano.total > 0) ...[
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: plano.progresso, minHeight: 7, backgroundColor: NorteColors.blush, color: NorteColors.rose),
        ),
        const SizedBox(height: 8),
        Text('${plano.concluidas} de ${plano.total} tarefas', style: const TextStyle(color: NorteColors.muted, fontSize: 13)),
      ],
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onAbrirPlano,
        icon: const Icon(Icons.calendar_view_week_rounded, size: 18),
        label: const Text('Abrir plano de 7 dias'),
        style: TextButton.styleFrom(foregroundColor: NorteColors.wine, padding: EdgeInsets.zero),
      ),
    ]);
  }
}
