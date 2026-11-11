import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Durações e curvas padrão da identidade Rose Edition.
/// Movimento discreto, acolhedor e sem pressa.
class NorteAnims {
  static const Duration rapido = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 380);
  static const Duration lento = Duration(milliseconds: 560);
  static const Duration entrada = Duration(milliseconds: 480);

  static const Curve curvaSuave = Curves.easeOutCubic;
  static const Curve curvaEntrada = Curves.easeOutQuart;
  static const Curve curvaSaida = Curves.easeInCubic;

  /// Atraso escalonado para listas e cards (stagger).
  static Duration atraso(int indice, {int passoMs = 55}) =>
      Duration(milliseconds: passoMs * indice);
}

/// Extensão conveniente para aplicar animações de entrada consistentes.
extension NorteAnimateX on Widget {
  /// Fade + leve slide de baixo para cima.
  Widget entrada({
    int delayMs = 0,
    Duration? duration,
    double dy = 18,
  }) {
    final duracao = duration ?? NorteAnims.entrada;
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: duracao, curve: NorteAnims.curvaEntrada)
        .slideY(
          begin: dy / 100,
          end: 0,
          duration: duracao,
          curve: NorteAnims.curvaEntrada,
        );
  }

  /// Fade simples e rápido.
  Widget fadeRapido({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: NorteAnims.rapido, curve: NorteAnims.curvaSuave);
  }

  /// Escala sutil de entrada.
  Widget escalaSuave({int delayMs = 0, double begin = 0.92}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: NorteAnims.normal)
        .scale(
          begin: Offset(begin, begin),
          end: const Offset(1, 1),
          duration: NorteAnims.normal,
          curve: NorteAnims.curvaSuave,
        );
  }
}

/// Transição de página suave (fade + leve slide).
class NortePageRoute<T> extends PageRouteBuilder<T> {
  NortePageRoute({required Widget page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: NorteAnims.normal,
          reverseTransitionDuration: NorteAnims.rapido,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: NorteAnims.curvaEntrada,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
