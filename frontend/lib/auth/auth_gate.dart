import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:norte_app/auth/auth_controller.dart';
import 'package:norte_app/auth/login_screen.dart';
import 'package:norte_app/core/norte_colors.dart';

/// Porteiro do app: restaura a sessão e mostra a tela correspondente.
class AuthGate extends StatefulWidget {
  const AuthGate({required this.auth, required this.logadoBuilder, super.key});

  final AuthController auth;
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final curva = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curva,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curva),
                child: child,
              ),
            );
          },
          child: switch (widget.auth.status) {
            AuthStatus.iniciando => const _SplashNorte(key: ValueKey('splash')),
            AuthStatus.deslogado => LoginScreen(
                key: const ValueKey('login'),
                auth: widget.auth,
              ),
            AuthStatus.logado => KeyedSubtree(
                key: const ValueKey('home'),
                child: widget.logadoBuilder(context),
              ),
          },
        );
      },
    );
  }
}

/// Splash acolhedor enquanto a sessão é restaurada.
class _SplashNorte extends StatelessWidget {
  const _SplashNorte({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NorteColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NorteColors.blush, NorteColors.nude],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x28A96D7B),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: NorteColors.wine,
                size: 46,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.06, 1.06),
                  duration: 1600.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 28),
            const Text(
              'NORTE',
              style: TextStyle(
                color: NorteColors.wine,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 5,
                fontFamily: 'Georgia',
              ),
            )
                .animate()
                .fadeIn(delay: 180.ms, duration: 500.ms)
                .slideY(begin: 0.15, end: 0, delay: 180.ms),
            const SizedBox(height: 10),
            const Text(
              'Um momento para se encontrar',
              style: TextStyle(color: NorteColors.muted, fontSize: 14),
            ).animate().fadeIn(delay: 320.ms, duration: 500.ms),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: NorteColors.rose,
              ),
            ).animate().fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }
}
