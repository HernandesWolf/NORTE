import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/login_screen.dart';

/// Porteiro do app: restaura a sessão ao abrir e mostra a tela certa
/// (carregando, entrar/cadastrar ou o app logado).
class AuthGate extends StatefulWidget {
  const AuthGate({required this.auth, required this.logadoBuilder, super.key});

  final AuthController auth;

  /// Constrói a tela principal, usada só quando há uma sessão válida.
  final WidgetBuilder logadoBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.auth.iniciar());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        switch (widget.auth.status) {
          case AuthStatus.iniciando:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.deslogado:
            return LoginScreen(auth: widget.auth);
          case AuthStatus.logado:
            return widget.logadoBuilder(context);
        }
      },
    );
  }
}
