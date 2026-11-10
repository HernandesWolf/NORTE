import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/core/norte_colors.dart';
import 'package:norte_app/tarefas/tarefas_api.dart';
import 'package:norte_app/tarefas/tarefas_models.dart';

/// Plano de 7 dias de um objetivo: as tarefas distribuídas de "Dia 1" a "Dia 7", mais as que ainda não têm dia.
class PlanoPage extends StatefulWidget {
  const PlanoPage({
    required this.auth,
    required this.api,
    required this.objetivoId,
    required this.objetivoTitulo,
    super.key,
  });

  final AuthController auth;
  final TarefasApi api;
  final String objetivoId;
  final String objetivoTitulo;

  @override
  State<PlanoPage> createState() => _PlanoPageState();
}

class _PlanoPageState extends State<PlanoPage> {
  Plano? _plano;
  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    try {
      final plano = await widget.auth.comSessao((token) => widget.api.plano(token, widget.objetivoId));
      if (!mounted) {
        return;
      }
      setState(() {
        _plano = plano;
        _carregando = false;
        _erro = null;
      });
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _carregando = false;
        _erro = e.mensagem;
      });
      if (_plano != null) {
        _avisar(e.mensagem);
      }
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  /// Faz uma alteração no servidor e, se deu certo, recarrega o plano para a tela ficar igual ao que foi gravado.
  Future<void> _mudar(Future<void> Function(String token) acao) async {
    if (_ocupado) {
      return;
    }
    setState(() => _ocupado = true);
    try {
      await widget.auth.comSessao(acao);
      await _carregar();
    } on ApiError catch (e) {
      _avisar(e.mensagem);
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  Future<void> _nova({int? diaInicial}) async {
    final dados = await showDialog<_DadosTarefa>(
      context: context,
      builder: (_) => _TarefaDialog(diaInicial: diaInicial),
    );
    if (dados == null || !mounted) {
      return;
    }
    await _mudar((token) => widget.api.criar(token, widget.objetivoId, dados.titulo, dados.dia));
  }

  Future<void> _editar(Tarefa tarefa) async {
    final dados = await showDialog<_DadosTarefa>(
      context: context,
      builder: (_) => _TarefaDialog(existente: tarefa),
    );
    if (dados == null || !mounted) {
      return;
    }
    await _mudar((token) => widget.api.atualizar(token, tarefa.id, dados.titulo, dados.dia));
  }

  Future<void> _alternar(Tarefa tarefa, bool concluida) =>
      _mudar((token) => widget.api.concluir(token, tarefa.id, concluida));

  Future<void> _excluir(Tarefa tarefa) => _mudar((token) => widget.api.excluir(token, tarefa.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.objetivoTitulo, maxLines: 1, overflow: TextOverflow.ellipsis)),
      floatingActionButton: _plano == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _ocupado ? null : () => unawaited(_nova()),
              backgroundColor: NorteColors.rose,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova tarefa'),
            ),
      body: SafeArea(child: _corpo()),
    );
  }

  Widget _corpo() {
    final plano = _plano;
    if (plano != null) {
      return _lista(plano);
    }
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _erro ?? 'Não foi possível abrir o plano.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: NorteColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _carregando = true;
                _erro = null;
              });
              unawaited(_carregar());
            },
            child: const Text('Tentar de novo'),
          ),
        ]),
      ),
    );
  }

  Widget _lista(Plano plano) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 96), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Seu progresso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              plano.total == 0 ? 'Nenhuma tarefa ainda' : '${plano.concluidas} de ${plano.total} concluídas',
              style: const TextStyle(color: NorteColors.muted),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plano.progresso,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: NorteColors.blush,
              color: NorteColors.rose,
            ),
          ]),
        ),
      ),
      if (plano.total == 0) ...[
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Comece com um passo pequeno. Distribua tarefas pelos 7 dias do jeito que couber na sua semana.',
              style: TextStyle(color: NorteColors.muted, height: 1.45),
            ),
          ),
        ),
      ],
      for (final dia in plano.dias) _secaoDia(dia),
      if (plano.semDia.isNotEmpty) _secaoSemDia(plano.semDia),
    ]);
  }

  Widget _secaoDia(DiaDoPlano dia) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: Text(
            'Dia ${dia.dia}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NorteColors.ink),
          ),
        ),
        IconButton(
          tooltip: 'Adicionar tarefa ao dia ${dia.dia}',
          onPressed: _ocupado ? null : () => unawaited(_nova(diaInicial: dia.dia)),
          icon: const Icon(Icons.add_circle_outline, color: NorteColors.rose),
        ),
      ]),
      if (dia.tarefas.isEmpty)
        const Text('Nada planejado para este dia.', style: TextStyle(color: NorteColors.muted, fontSize: 13))
      else
        for (final tarefa in dia.tarefas) _tile(tarefa),
    ]);
  }

  Widget _secaoSemDia(List<Tarefa> tarefas) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 22),
      const Text(
        'Ainda sem dia',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: NorteColors.ink),
      ),
      const SizedBox(height: 4),
      const Text(
        'Edite a tarefa para escolher um dia do plano.',
        style: TextStyle(color: NorteColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 8),
      for (final tarefa in tarefas) _tile(tarefa),
    ]);
  }

  Widget _tile(Tarefa tarefa) {
    return _TarefaTile(
      tarefa: tarefa,
      habilitado: !_ocupado,
      aoAlternar: (concluida) => unawaited(_alternar(tarefa, concluida)),
      aoEditar: () => unawaited(_editar(tarefa)),
      aoExcluir: () => unawaited(_excluir(tarefa)),
    );
  }
}

enum _Acao { editar, excluir }

class _TarefaTile extends StatelessWidget {
  const _TarefaTile({
    required this.tarefa,
    required this.habilitado,
    required this.aoAlternar,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Tarefa tarefa;
  final bool habilitado;
  final ValueChanged<bool> aoAlternar;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: tarefa.concluida,
            activeColor: NorteColors.rose,
            onChanged: habilitado ? (valor) => aoAlternar(valor ?? false) : null,
          ),
          title: Text(
            tarefa.titulo,
            style: TextStyle(
              height: 1.3,
              color: tarefa.concluida ? NorteColors.muted : NorteColors.ink,
              decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: PopupMenuButton<_Acao>(
            tooltip: 'Mais opções',
            enabled: habilitado,
            onSelected: (acao) => acao == _Acao.editar ? aoEditar() : aoExcluir(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Acao.editar, child: Text('Editar')),
              PopupMenuItem(value: _Acao.excluir, child: Text('Excluir')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DadosTarefa {
  const _DadosTarefa(this.titulo, this.dia);

  final String titulo;
  final int? dia;
}

/// Formulário para criar ou editar uma tarefa. É um widget próprio para o campo de texto ser descartado
/// junto com o diálogo, sem risco de ser usado depois de descartado durante a animação de fechar.
class _TarefaDialog extends StatefulWidget {
  const _TarefaDialog({this.existente, this.diaInicial});

  final Tarefa? existente;
  final int? diaInicial;

  @override
  State<_TarefaDialog> createState() => _TarefaDialogState();
}

class _TarefaDialogState extends State<_TarefaDialog> {
  late final TextEditingController _titulo = TextEditingController(text: widget.existente?.titulo ?? '');
  late int? _dia = widget.existente != null ? widget.existente!.dia : widget.diaInicial;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  void _salvar() {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'Informe o título da tarefa.');
      return;
    }
    Navigator.pop(context, _DadosTarefa(titulo, _dia));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existente == null ? 'Nova tarefa' : 'Editar tarefa'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _titulo,
            autofocus: true,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _salvar(),
            decoration: InputDecoration(labelText: 'O que você vai fazer?', errorText: _erro),
          ),
          const SizedBox(height: 12),
          const Text('Em qual dia?', style: TextStyle(color: NorteColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              label: const Text('Sem dia'),
              selected: _dia == null,
              showCheckmark: false,
              onSelected: (_) => setState(() => _dia = null),
            ),
            for (var dia = 1; dia <= 7; dia++)
              ChoiceChip(
                label: Text('Dia $dia'),
                selected: _dia == dia,
                showCheckmark: false,
                onSelected: (_) => setState(() => _dia = dia),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
