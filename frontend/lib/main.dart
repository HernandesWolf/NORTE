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
    backgroundColor: NorteColors.cream,
    appBar: AppBar(
      toolbarHeight: 88,
      backgroundColor: NorteColors.cream,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [NorteColors.wine, NorteColors.rose],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(color: Color(0x33A34D68), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 13),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('NORTE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.4, color: NorteColors.wine)),
          Text(titles[selected].toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: NorteColors.muted, fontWeight: FontWeight.w700)),
        ]),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: IconButton.filledTonal(
            tooltip: 'Notificações',
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: NorteColors.wine,
              fixedSize: const Size(46, 46),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(selected),
          child: pages[selected],
        ),
      ),
    ),
    bottomNavigationBar: _NorteBottomBar(selected: selected, onSelect: _irPara),
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
      height: 286,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF713B50), Color(0xFF9D526B), Color(0xFFC77D8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(color: Color(0x33713B50), blurRadius: 30, offset: Offset(0, 16)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -66,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .10), width: 30),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(.96, .96), end: const Offset(1.05, 1.05), duration: 5.seconds),
          ),
          Positioned(
            right: 26,
            bottom: 26,
            child: Icon(Icons.spa_rounded, size: 104, color: Colors.white.withValues(alpha: .10))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(begin: -.035, end: .035, duration: 7.seconds),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 23, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: .18)),
                    ),
                    child: const Text('ROSE EDITION  ·  SEU ESPAÇO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  ),
                  const Spacer(),
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFDCE4), size: 22)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(.9, .9), end: const Offset(1.16, 1.16), duration: 1.8.seconds),
                ]),
                const Spacer(),
                const Text(
                  'Respire.\nVocê pode recomeçar\num passo de cada vez.',
                  style: TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 27, height: 1.13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Um lugar para organizar o que sente, reconhecer o que importa e encontrar seu próximo passo.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.45, fontSize: 12.5),
                ),
                const SizedBox(height: 17),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: widget.onAbrirConversa,
                    borderRadius: BorderRadius.circular(15),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Começar por uma conversa', style: TextStyle(color: NorteColors.wine, fontWeight: FontWeight.w800, fontSize: 12)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: NorteColors.wine, size: 17),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF713B50), Color(0xFFA75D75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x26713B50), blurRadius: 22, offset: Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('SEU PROGRESSO', style: TextStyle(color: Color(0xFFFFE8ED), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8))),
            const Icon(Icons.trending_up_rounded, color: Color(0xFFFFE8ED), size: 22),
          ]),
          const SizedBox(height: 9),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$concluidos', style: const TextStyle(color: Colors.white, fontSize: 42, height: 1, fontWeight: FontWeight.w800)),
            Padding(padding: const EdgeInsets.only(left: 8, bottom: 5), child: Text('de ${_objetivos.length} objetivos concluídos', style: const TextStyle(color: Color(0xFFFFE8ED), fontSize: 12))),
          ]),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _objetivos.isEmpty ? 0 : concluidos / _objetivos.length),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 9, backgroundColor: Colors.white.withValues(alpha: .22), color: const Color(0xFFFFD9E2)),
            ),
          ),
          const SizedBox(height: 9),
          Text(_objetivos.isEmpty ? 'Todo caminho começa com uma escolha.' : '${((_objetivos.isEmpty ? 0 : concluidos / _objetivos.length) * 100).round()}% do caminho concluído', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ).entrada(delayMs: 120),
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
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 30), children: [
      Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF713B50), Color(0xFFB66B80)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.person_rounded, color: Colors.white, size: 31)),
          const SizedBox(height: 18),
          const Text('SEU ESPAÇO, SUAS ESCOLHAS', style: TextStyle(color: Color(0xFFFFE8ED), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 7),
          Text(usuario?.nomeOuEmail ?? 'Sua conta', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(usuario?.email ?? '', style: const TextStyle(color: Color(0xFFFFE8ED), fontSize: 13)),
        ]),
      ).entrada(delayMs: 50),
      const SizedBox(height: 22),
      const SectionHeading('Cuidado com seus dados', subtitle: 'Você está no controle do que compartilha.').entrada(delayMs: 120),
      const SizedBox(height: 12),
      _ProfileTile(icon: Icons.psychology_outlined, title: 'Contexto e memória', subtitle: 'Consultar, corrigir ou excluir informações').entrada(delayMs: 160),
      const SizedBox(height: 9),
      _ProfileTile(icon: Icons.privacy_tip_outlined, title: 'Privacidade e consentimentos', subtitle: 'Entenda como seus dados são utilizados').entrada(delayMs: 210),
      const SizedBox(height: 9),
      _ProfileTile(icon: Icons.download_outlined, title: 'Exportar meus dados').entrada(delayMs: 260),
      const SizedBox(height: 9),
      _ProfileTile(icon: Icons.delete_outline, title: 'Excluir minha conta').entrada(delayMs: 310),
      const SizedBox(height: 14),
      const Text('Contexto e memória, privacidade, exportação e exclusão ainda são ilustrativos: serão habilitados em uma próxima etapa.', style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: auth.sair,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: NorteColors.wine, side: const BorderSide(color: NorteColors.nude), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      ),
    ]);
  }
}

class _NorteBottomBar extends StatelessWidget {
  const _NorteBottomBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_rounded, 'Início'),
    (Icons.chat_bubble_rounded, 'Conversa'),
    (Icons.flag_rounded, 'Objetivos'),
    (Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF0E4E6))),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected == i ? const Color(0xFFF8E8EC) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedScale(
                        scale: selected == i ? 1.12 : 1,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        child: Icon(_items[i].$1, color: selected == i ? NorteColors.wine : NorteColors.muted, size: 21),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(fontSize: 10, fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500, color: selected == i ? NorteColors.wine : NorteColors.muted),
                        child: Text(_items[i].$2),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFF0E4E6))),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: NorteColors.blush, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: NorteColors.wine)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: NorteColors.ink, fontSize: 13)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: NorteColors.muted, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, color: NorteColors.rose),
    ),
  );
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
