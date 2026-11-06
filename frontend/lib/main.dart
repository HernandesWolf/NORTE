import 'package:flutter/material.dart';

void main() => runApp(const NorteApp());

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
  const NorteApp({super.key});
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
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen> {
  bool registering = false;
  bool obscure = true;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 22),
          Container(height: 76, width: 76, decoration: BoxDecoration(color: NorteColors.blush, borderRadius: BorderRadius.circular(26)),
            child: const Icon(Icons.explore_outlined, color: NorteColors.wine, size: 42)),
          const SizedBox(height: 24),
          const Text('NORTE', style: TextStyle(color: NorteColors.wine, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 4, fontFamily: 'Georgia')),
          const SizedBox(height: 8),
          const Text('Seu tempo. Sua história. Seu caminho.', style: TextStyle(color: NorteColors.wine, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('Um espaço para entender seu momento e encontrar um próximo passo possível.', style: TextStyle(color: NorteColors.muted, height: 1.5, fontSize: 15)),
          const SizedBox(height: 34),
          Text(registering ? 'Vamos começar com calma.' : 'Que bom ter você aqui.', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: NorteColors.ink)),
          const SizedBox(height: 8),
          Text(registering ? 'Crie seu acesso. Você decide o ritmo.' : 'Entre para continuar de onde parou.', style: const TextStyle(color: NorteColors.muted)),
          const SizedBox(height: 24),
          if (registering) ...[const TextField(decoration: InputDecoration(labelText: 'Como podemos chamar você?')), const SizedBox(height: 14)],
          const TextField(keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'E-mail')),
          const SizedBox(height: 14),
          TextField(obscureText: obscure, decoration: InputDecoration(labelText: 'Senha', suffixIcon: IconButton(
            onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 22),
          ElevatedButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NorteHome())),
            child: Text(registering ? 'Criar minha conta' : 'Entrar')),
          const SizedBox(height: 14),
          TextButton(onPressed: () => setState(() => registering = !registering), child: Text(registering ? 'Já tenho uma conta · Entrar' : 'Quero criar minha conta')),
          const SizedBox(height: 22),
          const Text('Protótipo visual: ainda não envia dados nem autentica contas. A conexão segura com o backend será integrada e testada antes do piloto.',
            textAlign: TextAlign.center, style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
        ],
      )),
    ))),
  );
}

class NorteHome extends StatefulWidget {
  const NorteHome({super.key});
  @override
  State<NorteHome> createState() => _NorteHomeState();
}
class _NorteHomeState extends State<NorteHome> {
  int selected = 0;
  final pages = const [OverviewPage(), ConversationPage(), GoalsPage(), ProfilePage()];
  final titles = const ['Seu espaço', 'Conversa', 'Seus caminhos', 'Seu perfil'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [const Icon(Icons.explore_outlined, color: NorteColors.rose), const SizedBox(width: 9),
      Text(titles[selected], style: const TextStyle(fontWeight: FontWeight.w700))]),
      actions: [IconButton(tooltip: 'Notificações', onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)), const SizedBox(width: 8)]),
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

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFF3DDDF), Color(0xFFFBF7F3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(26)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UM PASSO DE CADA VEZ', style: TextStyle(color: NorteColors.wine, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
        SizedBox(height: 14),
        Text('Você não precisa\nresolver tudo hoje.', style: TextStyle(color: NorteColors.ink, fontFamily: 'Georgia', fontSize: 29, height: 1.2)),
        SizedBox(height: 12),
        Text('Vamos entender o que importa agora e escolher um próximo passo que caiba na sua realidade.', style: TextStyle(color: NorteColors.wine, height: 1.5, fontSize: 14)),
      ])),
    const SizedBox(height: 24),
    const SectionHeading('Como você está chegando hoje?', subtitle: 'Não existe resposta certa. É só um ponto de partida.'),
    const SizedBox(height: 12),
    const Wrap(spacing: 9, runSpacing: 9, children: [
      MoodChip(label: 'Com energia', icon: Icons.wb_sunny_outlined), MoodChip(label: 'Indo devagar', icon: Icons.spa_outlined),
      MoodChip(label: 'Sobrecarregado(a)', icon: Icons.cloud_outlined), MoodChip(label: 'Ainda não sei', icon: Icons.help_outline),
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
        Text('$done de ' + tasks.length.toString() + ' passos marcados', style: const TextStyle(color: NorteColors.muted)),
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
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Seu espaço, suas escolhas', style: TextStyle(fontFamily: 'Georgia', fontSize: 27, color: NorteColors.ink)),
    const SizedBox(height: 8),
    const Text('Você terá controle sobre suas informações e sobre o que deseja compartilhar.', style: TextStyle(color: NorteColors.muted, height: 1.5)),
    const SizedBox(height: 22),
    const Card(child: ListTile(leading: Icon(Icons.person_outline, color: NorteColors.rose), title: Text('Dados pessoais'), subtitle: Text('Nome e informações da conta'))),
    const SizedBox(height: 10),
    const Card(child: ListTile(leading: Icon(Icons.psychology_outlined, color: NorteColors.rose), title: Text('Contexto e memória'), subtitle: Text('Consultar, corrigir ou excluir informações'))),
    const SizedBox(height: 10),
    const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined, color: NorteColors.rose), title: Text('Privacidade e consentimentos'), subtitle: Text('Entenda como seus dados são utilizados'))),
    const SizedBox(height: 10),
    const Card(child: ListTile(leading: Icon(Icons.download_outlined, color: NorteColors.rose), title: Text('Exportar meus dados'))),
    const SizedBox(height: 10),
    const Card(child: ListTile(leading: Icon(Icons.delete_outline, color: NorteColors.rose), title: Text('Excluir minha conta'))),
    const SizedBox(height: 20),
    const Text('Controles ilustrativos. As ações serão habilitadas após integração segura com o backend.', style: TextStyle(color: NorteColors.muted, fontSize: 12, height: 1.5)),
  ]);
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
  final String label; final IconData icon;
  const MoodChip({required this.label, required this.icon, super.key});
  @override
  Widget build(BuildContext context) => ActionChip(onPressed: () {},
    avatar: Icon(icon, size: 17, color: NorteColors.wine), label: Text(label), backgroundColor: NorteColors.surface,
    side: const BorderSide(color: NorteColors.nude), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)));
}
class SuggestionChip extends StatelessWidget {
  final String label;
  const SuggestionChip({required this.label, super.key});
  @override
  Widget build(BuildContext context) => ActionChip(onPressed: () {}, label: Text(label), backgroundColor: NorteColors.surface,
    side: const BorderSide(color: NorteColors.nude), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
}
