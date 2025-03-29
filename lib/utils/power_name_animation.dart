import 'dart:math';

class PowerNameAnimation {
  final String powerName;
  final DateTime startTime;
  double opacity = 0.0;
  double scale = 0.5;
  bool isDone = false;

  // Duração total da animação em milissegundos - mais curta para não atrapalhar
  static const int animationDuration = 1500;

  PowerNameAnimation({required this.powerName})
      : startTime = DateTime.now();

  // Atualiza o estado da animação
  void update() {
    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

    if (elapsedMs >= animationDuration) {
      isDone = true;
      return;
    }

    // Cálculo da opacidade simplificado
    if (elapsedMs < animationDuration * 0.2) {
      // Fase de entrada rápida
      opacity = (elapsedMs / (animationDuration * 0.2));
    } else if (elapsedMs < animationDuration * 0.7) {
      // Fase de estabilização
      opacity = 1.0;
    } else {
      // Fase de saída
      opacity = 1.0 - ((elapsedMs - animationDuration * 0.7) / (animationDuration * 0.3));
    }

    // Cálculo da escala simplificado
    if (elapsedMs < animationDuration * 0.2) {
      // Entrada com zoom
      scale = 0.8 + (elapsedMs / (animationDuration * 0.2)) * 0.2; // 0.8 -> 1.0
    } else if (elapsedMs < animationDuration * 0.7) {
      // Mantém estável
      scale = 1.0;
    } else {
      // Redução suave no final
      scale = 1.0 - ((elapsedMs - animationDuration * 0.7) / (animationDuration * 0.3)) * 0.2; // 1.0 -> 0.8
    }
  }
}
