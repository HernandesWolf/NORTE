import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:norte_app/auth/auth_api.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/auth_gate.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/checkin/checkin_api.dart';
import 'package:norte_app/checkin/checkin_models.dart';
import 'package:norte_app/conversa/conversa_api.dart';
import 'package:norte_app/conversa/conversa_page.dart';
import 'package:norte_app/core/api_config.dart';
import 'package:norte_app/core/norte_colors.dart';
import 'package:norte_app/core/norte_animations.dart';
import 'package:norte_app/core/token_storage.dart';
import 'package:norte_app/inicio/foco.dart';
import 'package:norte_app/inicio/foco_card.dart';
import 'package:norte_app/objetivos/objetivos_api.dart';
import 'package:norte_app/tarefas/plano_page.dart';
import 'package:norte_app/tarefas/tarefas_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController(
    api: HttpAuthApi(baseUrl: apiBaseUrl),
    storage: SecureTokenStorage(),
  );
  runApp(NorteApp(
    auth: auth,
    checkinApi: HttpCheckinApi(baseUrl: apiBaseUrl),
    objetivosApi: ObjetivosApi(baseUrl: apiBaseUrl),
    tarefasApi: HttpTarefasApi(baseUrl: apiBaseUrl),
    conversaApi: HttpConversaApi(baseUrl: apiBaseUrl),
  ));
}

class NorteApp extends StatelessWidget {
  const NorteApp({
    required this.auth,
    required this.checkinApi,
    required this.objetivosApi,
    required this.tarefasApi,
    required this.conversaApi,
    super.key,
  });

  final AuthController auth;
  final CheckinApi checkinApi;
  final ObjetivosApi objetivosApi;
  final TarefasApi tarefasApi;
  final ConversaApi conversaApi;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: NorteColors.rose, brightness: Brightness.light);
    return MaterialApp(
      title: 'NORTE', debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, colorScheme: scheme.copyWith(primary: NorteColors.rose, onPrimary: Colors.white, secondary: NorteColors.wine, surface: NorteColors.cream),
        scaffoldBackgroundColor: NorteColors.cream,
        appBarTheme: const AppBarTheme(backgroundColor: NorteColors.cream, foregroundColor: NorteColors.ink, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: NorteColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NorteColors.nude)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NorteColors.nude)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NorteColors.rose, width: 1.5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
          backgroundColor: NorteColors.rose, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        )),
        cardTheme: CardThemeData(color: NorteColors.surface, elevation: 0, margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFEFE5E1)))),
      ),
      home: AuthGate(auth: auth, logadoBuilder: (_) => NorteHome(
        auth: auth, checkinApi: checkinApi, objetivosApi: objetivosApi, tarefasApi: tarefasApi, conversaApi: conversaApi,
      )),
    );
  }
}

class NorteHome extends StatefulWidget {
  const NorteHome({
    required this.auth,
    required this.checkinApi,
    required this.objetivosApi,
    required this.tarefasApi,
    required this.conversaApi,
    super.key,
  });

  final AuthController auth;
  final CheckinApi checkinApi;
  final ObjetivosApi objetivosApi;
  final TarefasApi tarefasApi;
  final ConversaApi conversaApi;

  @override
  State<NorteHome> createState() => _NorteHomeState();
}
class _NorteHomeState extends State<NorteHome> {
  int selected = 0;

  /// Avisa a aba Início para recarregar o foco sempre que a pessoa volta para ela.
  final _recarregarInicio = ValueNotifier<int>(0);

  void _irPara(int aba) {
    if (aba == 0 && selected != 0) {
      _recarregarInicio.value++;
    }
    setState(() => selected = aba);
  }

  @override
  void dispose() {
    _recarregarInicio.dispose();
    super.dispose();
  }

  late final List<Widget> pages = [
    OverviewPage(
      auth: widget.auth,
      checkinApi: widget.checkinApi,
      objetivosApi: widget.objetivosApi,
      tarefasApi: widget.tarefasApi,
      recarregar: _recarregarInicio,
      onAbrirConversa: () => _irPara(1),
      onAbrirObjetivos: () => _irPara(2),
    ),
    ConversationPage(auth: widget.auth, api: widget.conversaApi),
    GoalsPage(auth: widget.auth, api: widget.objetivosApi, tarefasApi: widget.tarefasApi),
    ProfilePage(auth: widget.auth),
  ];
  final titles = const ['Seu espaço', 'Conversa', 'Seus caminhos', 'Seu perfil'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      titleSpacing: 20,
      title: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [NorteColors.blush, NorteColors.nude]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.explore_rounded, color: NorteColors.wine, size: 25),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('NORTE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2, color: NorteColors.wine)),
          Text(titles[selected], style: const TextStyle(fontSize: 12, color: NorteColors.muted, fontWeight: FontWeight.w500)),
        ]),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton.filledTonal(
            tooltip: 'Notificações',
            onPressed: () {},
            style: IconButton.styleFrom(backgroundColor: NorteColors.blush, foregroundColor: NorteColors.wine),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    ),
    body: SafeArea(child: IndexedStack(index: selected, children: pages)),
    bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: _irPara,
      backgroundColor: NorteColors.surface, indicatorColor: NorteColors.blush,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Conversa'),
        NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Objetivos'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
      ]),
  );
}

/// Opções do check-in, na ordem em que aparecem na tela.
const _opcoesCheckin = <(EstadoCheckin, String, IconData)>[
  (EstadoCheckin.comEnergia, 'Com energia', Icons.wb_sunny_outlined),
  (EstadoCheckin.indoDevagar, 'Indo devagar', Icons.spa_outlined),
  (EstadoCheckin.sobrecarregado, 'Sobrecarregado(a)', Icons.cloud_outlined),
  (EstadoCheckin.aindaNaoSei, 'Ainda não sei', Icons.help_outline),
];

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    required this.auth,
    required this.checkinApi,
    required this.objetivosApi,
    required this.tarefasApi,
    required this.recarregar,
    required this.onAbrirConversa,
    required this.onAbrirObjetivos,
    super.key,
  });

  final AuthController auth;
  final CheckinApi checkinApi;
  final ObjetivosApi objetivosApi;
  final TarefasApi tarefasApi;

  /// Muda de valor sempre que a pessoa volta para a aba Início, para o foco ser recalculado.
  final ValueListenable<int> recarregar;
  final VoidCallback onAbrirConversa;
  final VoidCallback onAbrirObjetivos;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  EstadoCheckin? _estado;
  bool _salvando = false;
  String? _erroMensagem;

  ResultadoFoco? _foco;
  bool _carregandoFoco = true;
  String? _erroFoco;

  /// Identifica a consulta mais recente para impedir que respostas antigas sobrescrevam dados novos.
  int _geracaoFoco = 0;

  @override
  void initState() {
    super.initState();
    widget.recarregar.addListener(_aoVoltarParaInicio);
    unawaited(_carregar());
    unawaited(_carregarFoco());
  }

  @override
  void dispose() {
    widget.recarregar.removeListener(_aoVoltarParaInicio);
    super.dispose();
  }

  void _aoVoltarParaInicio() => unawaited(_recarregarFoco());

  /// Recarrega o foco. Enquanto isso, o card antigo continua na tela.
  Future<void> _recarregarFoco() {
    setState(() {
      _carregandoFoco = true;
      _erroFoco = null;
    });
    return _carregarFoco();
  }

  /// Busca os objetivos e escolhe o que destacar.
  Future<void> _carregarFoco() async {
    final geracao = ++_geracaoFoco;
    try {
      final objetivos = await widget.auth.comSessao(widget.objetivosApi.listar);
      final foco = await calcularFoco(
        objetivos: objetivos,
        buscarPlano: (id) => widget.auth.comSessao((token) => widget.tarefasApi.plano(token, id)),
      );
      if (!mounted || geracao != _geracaoFoco) {
        return;
      }
      setState(() {
        _foco = foco;
        _carregandoFoco = false;
      });
    } on ApiError catch (e) {
      if (!mounted || geracao != _geracaoFoco) {
        return;
      }
      setState(() {
        _carregandoFoco = false;
        // Se já havia um foco na tela, ele continua valendo; só avisamos quando não há nada para mostrar.
        _erroFoco = _foco == null ? e.mensagem : null;
      });
    }
  }

  Future<void> _abrirPlano() async {
    final objetivo = _foco?.objetivo;
    if (objetivo == null) {
      return;
    }
    await Navigator.of(context).push(NortePageRoute<void>(
      page: PlanoPage(
        auth: widget.auth,
        api: widget.tarefasApi,
        objetivoId: objetivo.id,
        objetivoTitulo: objetivo.titulo,
      ),
    ));
    if (mounted) {
      unawaited(_recarregarFoco());
    }
  }

  Future<void> _carregar() async {
    try {
      final atual = await widget.auth.comSessao(widget.checkinApi.deHoje);
      if (!mounted) {
        return;
      }
      // `??=`: se a pessoa já tocou em uma opção enquanto carregava, a escolha dela vale mais que o valor antigo.
      setState(() => _estado ??= atual);
    } on ApiError {
      // Sem o check-in de hoje a tela continua útil: a pessoa pode escolher de novo.
    }
  }

  /// Marca na hora e grava em seguida. Se a gravação falhar, desfaz a marcação e avisa.
  Future<void> _escolher(EstadoCheckin novo) async {
    if (_salvando || novo == _estado) {
      return;
    }
    final anterior = _estado;
    setState(() {
      _estado = novo;
      _salvando = true;
      _erroMensagem = null;
    });
    try {
      final salvo = await widget.auth.comSessao((token) => widget.checkinApi.registrar(token, novo));
      if (!mounted) {
        return;
      }
      setState(() => _estado = salvo);
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _estado = anterior;
        _erroMensagem = e.mensagem;
      });
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: [
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1DDE0), Color(0xFFFFFBF8), Color(0xFFEFE1DC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEAD8D8)),
        boxShadow: const [BoxShadow(color: Color(0x18A96D7B), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.explore_rounded, color: NorteColors.wine, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('UM PASSO DE CADA VEZ', style: TextStyle(color: NorteColors.wine, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const Spacer(),
          const Icon(Icons.auto_awesome_rounded, color: NorteColors.rose, size: 19)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.12, 1.12),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),
        ]),
        const SizedBox(height: 20),
        const Text('Você não precisa\nresolver tudo hoje.', style: TextStyle(color: NorteColors.ink, fontFamily: 'Georgia', fontSize: 30, height: 1.16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 13),
        const Text('Vamos entender o que importa agora e escolher um próximo passo que caiba na sua realidade.', style: TextStyle(color: NorteColors.wine, height: 1.55, fontSize: 14)),
        const SizedBox(height: 18),
        Container(height: 3, width: 58, decoration: BoxDecoration(color: NorteColors.rose, borderRadius: BorderRadius.circular(8))),
      ]),
    ).entrada(delayMs: 40),
    const SizedBox(height: 24),
    const SectionHeading('Como você está chegando hoje?', subtitle: 'Não existe resposta certa. É só um ponto de partida.')
        .entrada(delayMs: 120),
    const SizedBox(height: 12),
    Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (var i = 0; i < _opcoesCheckin.length; i++)
          MoodChip(
            label: _opcoesCheckin[i].$2,
            icon: _opcoesCheckin[i].$3,
            selected: _estado == _opcoesCheckin[i].$1,
            onTap: () => unawaited(_escolher(_opcoesCheckin[i].$1)),
            index: i,
          ).entrada(delayMs: 160 + (i * 55)),
      ],
    ),
    if (_erroMensagem != null) ...[
      const SizedBox(height: 10),
      Text(_erroMensagem!, style: const TextStyle(color: Color(0xFF9B3D4A), fontSize: 13)),
    ],
    const SizedBox(height: 24),
    const SectionHeading('Seu foco neste momento', subtitle: 'Pequenas ações também são progresso.')
        .entrada(delayMs: 280),
    const SizedBox(height: 12),
    FocoCard(
      carregando: _carregandoFoco,
      resultado: _foco,
      erro: _erroFoco,
      onAbrirPlano: () => unawaited(_abrirPlano()),
      onAbrirObjetivos: widget.onAbrirObjetivos,
      onTentarDeNovo: () => unawaited(_recarregarFoco()),
    ).entrada(delayMs: 340),
    const SizedBox(height: 24),
    Card(child: ListTile(contentPadding: const EdgeInsets.all(16),
      onTap: widget.onAbrirConversa,
      leading: const CircleAvatar(backgroundColor: NorteColors.blush, child: Icon(Icons.chat_outlined, color: NorteColors.wine)),
      title: const Text('Quer conversar um pouco?', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: const Text('Pode começar pelo que está pesando ou pelo que você deseja mudar.'),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NorteColors.rose)))
        .entrada(delayMs: 400),
  ]);
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({required this.auth, required this.api, required this.tarefasApi, super.key});
  final AuthController auth;
  final ObjetivosApi api;
  final TarefasApi tarefasApi;
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final List<Objetivo> _objetivos = [];
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final itens = await widget.auth.comSessao(widget.api.listar);
      if (!mounted) return;
      setState(() {
        _objetivos
          ..clear()
          ..addAll(itens);
        _carregando = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _adicionar() async {
    final dados = await showDialog<_DadosObjetivo>(context: context, builder: (_) => const _ObjetivoDialog());
    if (dados == null || !mounted || _salvando) return;
    setState(() => _salvando = true);
    try {
      final novo = await widget.auth.comSessao((token) => widget.api.criar(token, dados.titulo, dados.descricao));
      if (!mounted) return;
      setState(() => _objetivos.insert(0, novo));
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editar(Objetivo item) async {
    final dados = await showDialog<_DadosObjetivo>(context: context, builder: (_) => _ObjetivoDialog(existente: item));
    if (dados == null || !mounted || _salvando) return;
    setState(() => _salvando = true);
    try {
      final atualizado = await widget.auth.comSessao(
        (token) => widget.api.atualizar(token, item.id, dados.titulo, dados.descricao),
      );
      if (!mounted) return;
      setState(() {
        final index = _objetivos.indexWhere((o) => o.id == item.id);
        if (index >= 0) _objetivos[index] = atualizado;
      });
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alternar(Objetivo item, bool concluido) async {
    try {
      final atualizado = await widget.auth.comSessao((token) => widget.api.concluir(token, item.id, concluido));
      if (!mounted) return;
      setState(() {
        final index = _objetivos.indexWhere((o) => o.id == item.id);
        if (index >= 0) _objetivos[index] = atualizado;
      });
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _excluir(Objetivo item) async {
    try {
      await widget.auth.comSessao((token) => widget.api.excluir(token, item.id));
      if (mounted) setState(() => _objetivos.removeWhere((o) => o.id == item.id));
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  void _abrirPlano(Objetivo item) {
    Navigator.of(context).push(NortePageRoute<void>(
      page: PlanoPage(
        auth: widget.auth,
        api: widget.tarefasApi,
        objetivoId: item.id,
        objetivoTitulo: item.titulo,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final concluidos = _objetivos.where((o) => o.concluido).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Seu caminho, no seu ritmo', style: TextStyle(fontFamily: 'Georgia', fontSize: 27, color: NorteColors.ink)),
          SizedBox(height: 8),
          Text('Objetivos reais, construídos por você.', style: TextStyle(color: NorteColors.muted)),
        ])),
        IconButton.filledTonal(onPressed: _salvando ? null : _adicionar,
          icon: const Icon(Icons.add), tooltip: 'Adicionar objetivo'),
      ]),
      const SizedBox(height: 22),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Seu progresso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('$concluidos de ${_objetivos.length} objetivos concluídos', style: const TextStyle(color: NorteColors.muted)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: _objetivos.isEmpty ? 0 : concluidos / _objetivos.length,
          minHeight: 7, borderRadius: BorderRadius.circular(10), backgroundColor: NorteColors.blush, color: NorteColors.rose),
      ]))),
      const SizedBox(height: 20),
      if (_carregando) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
      else if (_objetivos.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        const Icon(Icons.flag_outlined, size: 34, color: NorteColors.rose),
        const SizedBox(height: 10),
        const Text('Seu próximo passo começa aqui', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Adicione um objetivo que faça sentido para sua realidade. Ele ficará salvo na sua conta.', textAlign: TextAlign.center,
          style: TextStyle(color: NorteColors.muted, height: 1.4)),
        const SizedBox(height: 14),
        ElevatedButton.icon(onPressed: _adicionar, icon: const Icon(Icons.add), label: const Text('Criar meu primeiro objetivo')),
      ])))
      else ..._objetivos.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Column(children: [
            CheckboxListTile(
              value: item.concluido,
              activeColor: NorteColors.rose,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(item.titulo, style: TextStyle(height: 1.3,
                decoration: item.concluido ? TextDecoration.lineThrough : null)),
              subtitle: item.descricao == null ? null : Text(item.descricao!),
              secondary: IconButton(onPressed: () => _excluir(item), tooltip: 'Excluir objetivo',
                icon: const Icon(Icons.delete_outline, color: NorteColors.muted)),
              onChanged: (value) => _alternar(item, value ?? false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 4, children: [
                  TextButton.icon(
                    onPressed: () => _abrirPlano(item),
                    icon: const Icon(Icons.calendar_view_week_rounded, size: 18),
                    label: const Text('Plano de 7 dias'),
                    style: TextButton.styleFrom(foregroundColor: NorteColors.wine),
                  ),
                  TextButton.icon(
                    onPressed: () => _editar(item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(foregroundColor: NorteColors.wine),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      )),
      const SizedBox(height: 12),
      const Text('Seus objetivos são privados e vinculados à sua conta.', style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
    ]);
  }
}

class _DadosObjetivo {
  const _DadosObjetivo(this.titulo, this.descricao);

  final String titulo;
  final String? descricao;
}

/// Formulário para criar ou editar um objetivo. Widget próprio para os campos serem descartados junto com o diálogo.
class _ObjetivoDialog extends StatefulWidget {
  const _ObjetivoDialog({this.existente});

  final Objetivo? existente;

  @override
  State<_ObjetivoDialog> createState() => _ObjetivoDialogState();
}

class _ObjetivoDialogState extends State<_ObjetivoDialog> {
  late final TextEditingController _titulo = TextEditingController(text: widget.existente?.titulo ?? '');
  late final TextEditingController _descricao = TextEditingController(text: widget.existente?.descricao ?? '');
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  void _salvar() {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      setState(() => _erro = 'Informe o título do objetivo.');
      return;
    }
    final detalhe = _descricao.text.trim();
    Navigator.pop(context, _DadosObjetivo(titulo, detalhe.isEmpty ? null : detalhe));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existente == null ? 'Novo objetivo' : 'Editar objetivo'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _titulo, autofocus: true, maxLength: 120,
            decoration: InputDecoration(labelText: 'O que você deseja alcançar?', errorText: _erro)),
          const SizedBox(height: 10),
          TextField(controller: _descricao, maxLength: 500, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Detalhes (opcional)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.auth, super.key});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final usuario = auth.usuario;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Seu espaço, suas escolhas', style: TextStyle(fontFamily: 'Georgia', fontSize: 27, color: NorteColors.ink)),
      const SizedBox(height: 8),
      const Text('Você terá controle sobre suas informações e sobre o que deseja compartilhar.', style: TextStyle(color: NorteColors.muted, height: 1.5)),
      const SizedBox(height: 22),
      Card(child: ListTile(
        leading: const CircleAvatar(backgroundColor: NorteColors.blush, child: Icon(Icons.person_outline, color: NorteColors.wine)),
        title: Text(usuario?.nomeOuEmail ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(usuario?.email ?? ''),
      )),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Icon(Icons.psychology_outlined, color: NorteColors.rose), title: Text('Contexto e memória'), subtitle: Text('Consultar, corrigir ou excluir informações'))),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined, color: NorteColors.rose), title: Text('Privacidade e consentimentos'), subtitle: Text('Entenda como seus dados são utilizados'))),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Icon(Icons.download_outlined, color: NorteColors.rose), title: Text('Exportar meus dados'))),
      const SizedBox(height: 10),
      const Card(child: ListTile(leading: Icon(Icons.delete_outline, color: NorteColors.rose), title: Text('Excluir minha conta'))),
      const SizedBox(height: 20),
      const Text('Contexto e memória, privacidade, exportação e exclusão ainda são ilustrativos: serão habilitados em uma próxima etapa.', style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: auth.sair,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: NorteColors.wine, side: const BorderSide(color: NorteColors.nude)),
      ),
    ]);
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionHeading(this.title, {this.subtitle, super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: NorteColors.ink)),
    if (subtitle != null) ...[const SizedBox(height: 5), Text(subtitle!, style: const TextStyle(color: NorteColors.muted, fontSize: 13, height: 1.4))],
  ]);
}

class MoodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  const MoodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(icon, size: 17, color: selected ? NorteColors.wine : NorteColors.muted),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? NorteColors.ink : NorteColors.muted,
        ),
      ),
      backgroundColor: NorteColors.surface,
      selectedColor: NorteColors.blush,
      side: BorderSide(
        color: selected ? NorteColors.rose : NorteColors.nude,
        width: selected ? 1.6 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: selected ? 1 : 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    )
        .animate(target: selected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.035, 1.035),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
  }
}
