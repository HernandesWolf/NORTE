import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:norte_app/auth/auth_controller.dart';

// Mesmas cores do tema do app (definidas em main.dart); repetidas aqui para esta tela não depender dele.
const _vinho = Color(0xFF76505D);
const _rosa = Color(0xFFB87583);
const _suave = Color(0xFFF3DDDF);
const _texto = Color(0xFF49363D);
const _apagado = Color(0xFF88777B);

/// Tela de entrada: alterna entre "entrar" e "criar conta", valida os campos antes de enviar
/// e mostra os erros que o servidor devolver (e-mail já usado, senha errada, muitas tentativas...).
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.auth, super.key});

  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _formatoEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _cadastrando = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    widget.auth.limparErros();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    // Se der certo, o AuthGate troca a tela sozinho; se falhar, a mensagem aparece pelo controller.
    if (_cadastrando) {
      await widget.auth.cadastrar(
        nome: _nome.text,
        email: _email.text,
        senha: _senha.text,
      );
    } else {
      await widget.auth.entrar(email: _email.text, senha: _senha.text);
    }
  }

  void _alternarModo() {
    widget.auth.limparErros();
    setState(() => _cadastrando = !_cadastrando);
  }

  String? _validarEmail(String? valor) {
    final email = valor?.trim() ?? '';
    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }
    if (email.length > 255 || !_formatoEmail.hasMatch(email)) {
      return 'E-mail inválido.';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    final senha = valor ?? '';
    if (senha.isEmpty) {
      return 'Informe a senha.';
    }
    if (_cadastrando) {
      if (senha.length < 8) {
        return 'A senha deve ter pelo menos 8 caracteres.';
      }
      // O servidor limita a 72 bytes (limite do BCrypt); acentos e símbolos ocupam mais de um byte.
      if (utf8.encode(senha).length > 72) {
        return 'A senha é longa demais. Use no máximo 72 bytes.';
      }
    }
    return null;
  }

  String? _validarNome(String? valor) {
    if ((valor?.trim().length ?? 0) > 100) {
      return 'O nome deve ter no máximo 100 caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListenableBuilder(
                listenable: widget.auth,
                builder: (context, _) => _formulario(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final auth = widget.auth;
    final ocupado = auth.ocupado;
    final erros = auth.errosCampos;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(color: _suave, borderRadius: BorderRadius.circular(26)),
              child: const Icon(Icons.explore_outlined, color: _vinho, size: 42),
            ),
            const SizedBox(height: 24),
            const Text(
              'NORTE',
              style: TextStyle(
                color: _vinho,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seu tempo. Sua história. Seu caminho.',
              style: TextStyle(color: _vinho, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Um espaço para entender seu momento e encontrar um próximo passo possível.',
              style: TextStyle(color: _apagado, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 34),
            Text(
              _cadastrando ? 'Vamos começar com calma.' : 'Que bom ter você aqui.',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: _texto),
            ),
            const SizedBox(height: 8),
            Text(
              _cadastrando
                  ? 'Crie seu acesso. Você decide o ritmo.'
                  : 'Entre para continuar de onde parou.',
              style: const TextStyle(color: _apagado),
            ),
            const SizedBox(height: 24),
            if (_cadastrando) ...[
              TextFormField(
                controller: _nome,
                enabled: !ocupado,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                validator: _validarNome,
                decoration: InputDecoration(
                  labelText: 'Como podemos chamar você?',
                  errorText: erros['nomeExibicao'],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              enabled: !ocupado,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validarEmail,
              decoration: InputDecoration(labelText: 'E-mail', errorText: erros['email']),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _senha,
              enabled: !ocupado,
              obscureText: _ocultarSenha,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _cadastrando ? AutofillHints.newPassword : AutofillHints.password,
              ],
              validator: _validarSenha,
              onFieldSubmitted: (_) => ocupado ? null : _enviar(),
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: _cadastrando ? 'Pelo menos 8 caracteres.' : null,
                errorText: erros['senha'],
                suffixIcon: IconButton(
                  tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                  icon: Icon(
                    _ocultarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            // Se o servidor já apontou o campo com problema, o aviso fica no próprio campo (sem repetir aqui).
            if (auth.mensagemErro != null && erros.isEmpty) ...[
              const SizedBox(height: 16),
              _CaixaDeErro(mensagem: auth.mensagemErro!),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: ocupado ? null : _enviar,
              child: ocupado
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(_cadastrando ? 'Criar minha conta' : 'Entrar'),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: ocupado ? null : _alternarModo,
              child: Text(
                _cadastrando ? 'Já tenho uma conta · Entrar' : 'Quero criar minha conta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaixaDeErro extends StatelessWidget {
  const _CaixaDeErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _suave,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _rosa),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: _vinho, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mensagem, style: const TextStyle(color: _texto, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
