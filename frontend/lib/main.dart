import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norte_app/auth/auth_api.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/auth_gate.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/checkin/checkin_api.dart';
import 'package:norte_app/checkin/checkin_models.dart';
import 'package:norte_app/core/api_config.dart';
import 'package:norte_app/core/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController(
    api: HttpAuthApi(baseUrl: apiBaseUrl),
    storage: SecureTokenStorage(),
  );
  runApp(NorteApp(auth: auth, checkinApi: HttpCheckinApi(baseUrl: apiBaseUrl)));
}

class NorteColors {
  static const rose = Color(0xFFB87583);
  static const blush = Color(0xFFF3DDDF);
  static const cream = Color(0xFFFBF7F3);
  static const nude = Color(0xFFE9DCD3);
  static const wine = Color(0xFF76505D);
  static const muted = Color(0xFF88777B);
  static const surface = Color(0xFFFFFDFC);
  static const ink = Color(0xFF49363D);
}

class NorteApp extends StatelessWidget {
  const NorteApp({required this.auth, required this.checkinApi, super.key});

  final AuthController auth;
  final CheckinApi checkinApi;

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
      home: AuthGate(auth: auth, logadoBuilder: (_) => NorteHome(auth: auth, checkinApi: checkinApi)),
    );
  }
}

class NorteHome extends StatefulWidget {
  const NorteHome({required this.auth, required this.checkinApi, super.key});

  final AuthController auth;
  final CheckinApi checkinApi;

  @override
  State<NorteHome> createState() => _NorteHomeState();
}
class _NorteHomeState extends State<NorteHome> {
  int selected = 0;
  late final List<Widget> pages = [
    OverviewPage(auth: widget.auth, checkinApi: widget.checkinApi),
    const ConversationPage(),
    const GoalsPage(),
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
    bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: (v) => setState(() => selected = v),
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
  const OverviewPage({required this.auth, required this.checkinApi, super.key});

  final AuthController auth;
  final CheckinApi checkinApi;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  EstadoCheckin? _estado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
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
      setState(() => _estado = anterior);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
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
          const Icon(Icons.auto_awesome_rounded, color: NorteColors.rose, size: 19),
        ]),
        const SizedBox(height: 20),
        const Text('Você não precisa\nresolver tudo hoje.', style: TextStyle(color: NorteColors.ink, fontFamily: 'Georgia', fontSize: 30, height: 1.16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 13),
        const Text('Vamos entender o que importa agora e escolher um próximo passo que caiba na sua realidade.', style: TextStyle(color: NorteColors.wine, height: 1.55, fontSize: 14)),
        const SizedBox(height: 18),
        Container(height: 3, width: 58, decoration: BoxDecoration(color: NorteColors.rose, borderRadius: BorderRadius.circular(8))),
      ]),
    ),
    const SizedBox(height: 24),
    const SectionHeading('Como você está chegando hoje?', subtitle: 'Não existe resposta certa. É só um ponto de partida.'),
    const SizedBox(height: 12),
    Wrap(spacing: 9, runSpacing: 9, children: [
      for (final (estado, rotulo, icone) in _opcoesCheckin)
        MoodChip(label: rotulo, icon: icone, selected: _estado == estado, onTap: () => unawaited(_escolher(estado))),
    ]),
    const SizedBox(height: 24),
    const SectionHeading('Seu foco neste momento', subtitle: 'Pequenas ações também são progresso.'),
    const SizedBox(height: 12),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.flag_outlined, color: NorteColors.rose), SizedBox(width: 9), Text('Um caminho em construção', style: TextStyle(fontWeight: FontWeight.w700, color: NorteColors.ink))]),
      const SizedBox(height: 12),
      const Text('Organizar o próximo passo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: const LinearProgressIndicator(value: .25, minHeight: 7, backgroundColor: NorteColors.blush, color: NorteColors.rose)),
      const SizedBox(height: 8),
      const Text('O plano será construído junto com você.', style: TextStyle(color: NorteColors.muted, fontSize: 13)),
    ]))),
    const SizedBox(height: 24),
    const Card(child: ListTile(contentPadding: EdgeInsets.all(16),
      leading: CircleAvatar(backgroundColor: NorteColors.blush, child: Icon(Icons.chat_outlined, color: NorteColors.wine)),
      title: Text('Quer conversar um pouco?', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('Pode começar pelo que está pesando ou pelo que você deseja mudar.'),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NorteColors.rose))),
  ]);
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}
class _ConversationPageState extends State<ConversationPage> {
  final controller = TextEditingController();
  final messages = <String>[];
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: NorteColors.blush, borderRadius: BorderRadius.circular(20)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NORTE', style: TextStyle(color: NorteColors.wine, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          SizedBox(height: 8),
          Text('Estou aqui para ajudar você a organizar as ideias, sem pressa e sem julgamento. O que seria importante olhar hoje?', style: TextStyle(color: NorteColors.ink, height: 1.5)),
        ])),
      for (final message in messages) ...[
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: Container(constraints: const BoxConstraints(maxWidth: 300), padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: NorteColors.wine, borderRadius: BorderRadius.circular(18)),
          child: Text(message, style: const TextStyle(color: Colors.white, height: 1.4)))),
      ],
      const SizedBox(height: 14),
      const Text('Você pode começar por:', style: TextStyle(color: NorteColors.muted, fontSize: 13)),
      const SizedBox(height: 9),
      const Wrap(spacing: 8, runSpacing: 8, children: [
        SuggestionChip(label: 'Estou sobrecarregado(a)'), SuggestionChip(label: 'Quero mudar de carreira'), SuggestionChip(label: 'Preciso encontrar direção'),
      ]),
    ])),
    Container(padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(color: NorteColors.surface, border: Border(top: BorderSide(color: NorteColors.nude))),
      child: Row(children: [
        Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Escreva no seu tempo...', isDense: true))),
        const SizedBox(width: 9),
        IconButton.filled(style: IconButton.styleFrom(backgroundColor: NorteColors.rose, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
          onPressed: () { final value = controller.text.trim(); if (value.isEmpty) return; setState(() { messages.add(value); controller.clear(); }); },
          icon: const Icon(Icons.arrow_upward_rounded)),
      ])),
  ]);
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});
  @override
  State<GoalsPage> createState() => _GoalsPageState();
}
class _GoalsPageState extends State<GoalsPage> {
  final Map<String, bool> tasks = {
    'Escolher uma prioridade para esta semana': false,
    'Reservar 15 minutos para começar': false,
    'Revisar como foi o primeiro passo': false,
  };
  @override
  Widget build(BuildContext context) {
    final done = tasks.values.where((v) => v).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Seu caminho, no seu ritmo', style: TextStyle(fontFamily: 'Georgia', fontSize: 27, color: NorteColors.ink)),
      const SizedBox(height: 8),
      const Text('Um plano bom é aquele que conversa com a vida real.', style: TextStyle(color: NorteColors.muted)),
      const SizedBox(height: 22),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Plano de 7 dias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('$done de ${tasks.length} passos marcados', style: const TextStyle(color: NorteColors.muted)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: done / tasks.length, minHeight: 7, borderRadius: BorderRadius.circular(10), backgroundColor: NorteColors.blush, color: NorteColors.rose),
      ]))),
      const SizedBox(height: 20),
      const SectionHeading('Passos possíveis'),
      const SizedBox(height: 10),
      ...tasks.entries.map((entry) => Card(child: CheckboxListTile(
        value: entry.value, activeColor: NorteColors.rose, controlAffinity: ListTileControlAffinity.leading,
        title: Text(entry.key, style: const TextStyle(height: 1.35)),
        onChanged: (value) => setState(() => tasks[entry.key] = value ?? false),
      ))),
      const SizedBox(height: 12),
      const Text('Estes são exemplos demonstrativos. O plano real será criado e adaptado com você.', style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
    ]);
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
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  const MoodChip({required this.label, required this.icon, required this.selected, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => ChoiceChip(selected: selected, onSelected: (_) => onTap(), showCheckmark: false,
    avatar: Icon(icon, size: 17, color: NorteColors.wine), label: Text(label),
    backgroundColor: NorteColors.surface, selectedColor: NorteColors.blush,
    side: BorderSide(color: selected ? NorteColors.rose : NorteColors.nude, width: selected ? 1.5 : 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)));
}
class SuggestionChip extends StatelessWidget {
  final String label;
  const SuggestionChip({required this.label, super.key});
  @override
  Widget build(BuildContext context) => ActionChip(onPressed: () {}, label: Text(label), backgroundColor: NorteColors.surface,
    side: const BorderSide(color: NorteColors.nude), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
}
