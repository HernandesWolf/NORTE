import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/auth_models.dart';
import 'package:norte_app/conversa/conversa_api.dart';
import 'package:norte_app/core/norte_colors.dart';
import 'package:norte_app/core/norte_animations.dart';

/// Aba de conversa com a IA. A conversa vive só nesta tela (o servidor não a guarda): ao fechar o app, ela some.
class ConversationPage extends StatefulWidget {
  const ConversationPage({required this.auth, required this.api, super.key});

  final AuthController auth;
  final ConversaApi api;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  static const _sugestoes = ['Estou sobrecarregado(a)', 'Quero mudar de carreira', 'Preciso encontrar direção'];

  final _campo = TextEditingController();
  final _rolagem = ScrollController();
  final List<MensagemConversa> _mensagens = [];
  bool _enviando = false;

  @override
  void dispose() {
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// Envia o que está no campo, ou [texto] (usado pelos atalhos de sugestão).
  Future<void> _enviar([String? texto]) async {
    final mensagem = (texto ?? _campo.text).trim();
    if (mensagem.isEmpty || _enviando) return;

    final historico = List<MensagemConversa>.of(_mensagens);
    setState(() {
      _mensagens.add(MensagemConversa(papel: PapelConversa.usuario, texto: mensagem));
      _enviando = true;
      if (texto == null) _campo.clear();
    });
    _rolarParaOFim();

    try {
      final resposta = await widget.auth.comSessao((token) => widget.api.responder(token, mensagem, historico));
      if (!mounted) return;
      setState(() => _mensagens.add(MensagemConversa(papel: PapelConversa.assistente, texto: resposta)));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        // Não deixa a mensagem "enviada" sem resposta: devolve o texto ao campo para a pessoa tentar de novo.
        _mensagens.removeLast();
        if (texto == null && _campo.text.isEmpty) _campo.text = mensagem;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    _rolarParaOFim();
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rolagem.hasClients) return;
      _rolagem.animateTo(
        _rolagem.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: ListView(controller: _rolagem, padding: const EdgeInsets.all(20), children: [
            const _CartaoDeBoasVindas(),
            for (final mensagem in _mensagens) ...[
              const SizedBox(height: 14),
              _Balao(mensagem: mensagem),
            ],
            if (_enviando) ...[
              const SizedBox(height: 14),
              const _Digitando(),
            ],
            if (_mensagens.isEmpty) ...[
              const SizedBox(height: 14),
              const Text('Você pode começar por:', style: TextStyle(color: NorteColors.muted, fontSize: 13)),
              const SizedBox(height: 9),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final sugestao in _sugestoes)
                  ActionChip(
                    label: Text(sugestao),
                    onPressed: _enviando ? null : () => _enviar(sugestao),
                    backgroundColor: NorteColors.surface,
                    side: const BorderSide(color: NorteColors.nude),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              ]),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
            color: NorteColors.surface,
            border: Border(top: BorderSide(color: NorteColors.nude)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _campo,
                minLines: 1,
                maxLines: 4,
                maxLength: maxCaracteresPorMensagem,
                // O limite vale, mas o contador de caracteres ficaria poluindo a tela.
                buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                decoration: const InputDecoration(hintText: 'Escreva no seu tempo...', isDense: true),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              tooltip: 'Enviar',
              style: IconButton.styleFrom(
                backgroundColor: NorteColors.rose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
              onPressed: _enviando ? null : () => _enviar(),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ]),
        ),
      ]);
}

class _CartaoDeBoasVindas extends StatelessWidget {
  const _CartaoDeBoasVindas();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF713B50), Color(0xFF9D526B), Color(0xFFC77D8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: const [BoxShadow(color: Color(0x28713B50), blurRadius: 24, offset: Offset(0, 11))],
      ),
      child: Stack(children: [
        Positioned(right: -24, top: -36, child: Container(
          width: 150, height: 150,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .10), width: 22)),
        )),
        Padding(
          padding: const EdgeInsets.all(21),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21)),
              const SizedBox(width: 10),
              const Text('UM ESPAÇO DE ESCUTA', style: TextStyle(color: Color(0xFFFFE8ED), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 20),
            const Text('Pode chegar\ncomo você está.', style: TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 29, height: 1.12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Estou aqui para ajudar você a organizar as ideias, sem pressa e sem julgamento. O que seria importante olhar hoje?',
              style: TextStyle(color: Colors.white.withValues(alpha: .9), height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 17),
            Container(height: 1, color: Colors.white.withValues(alpha: .22)),
            const SizedBox(height: 12),
            const Text(
              'O NORTE usa inteligência artificial e pode errar. Não compartilhe senhas, documentos ou dados bancários.',
              style: TextStyle(color: Color(0xFFFFE8ED), fontSize: 10.5, height: 1.45),
            ),
          ]),
        ),
      ]),
    ).entrada(delayMs: 80);
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem});

  final MensagemConversa mensagem;

  @override
  Widget build(BuildContext context) {
    final daPessoa = mensagem.papel == PapelConversa.usuario;
    return Align(
      alignment: daPessoa ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: daPessoa ? NorteColors.wine : NorteColors.blush,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          mensagem.texto,
          style: TextStyle(color: daPessoa ? Colors.white : NorteColors.ink, height: 1.4),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _Digitando extends StatelessWidget {
  const _Digitando();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: NorteColors.blush,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NorteColors.wine,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1200.ms),
            const SizedBox(width: 10),
            const Text(
              'NORTE está pensando…',
              style: TextStyle(color: NorteColors.wine, fontSize: 13),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.1, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}
