import 'dart:math';

import 'package:flutter/material.dart';

class CollisionDetector {
  // Detecta colisão entre dois círculos
  static bool circleCollision(
      Offset center1, double radius1,
      Offset center2, double radius2,
      ) {
    // Calcular distância entre os centros
    final dx = center1.dx - center2.dx;
    final dy = center1.dy - center2.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Verificar se a distância é menor que a soma dos raios
    return distance < (radius1 + radius2);
  }

  // Detecta colisão entre um círculo e um retângulo
  static bool circleRectCollision(
      Offset circleCenter, double circleRadius,
      Rect rect,
      ) {
    // Encontrar o ponto mais próximo do círculo dentro do retângulo
    final closestX = _clamp(circleCenter.dx, rect.left, rect.right);
    final closestY = _clamp(circleCenter.dy, rect.top, rect.bottom);
    final closestPoint = Offset(closestX, closestY);

    // Calcular distância entre o centro do círculo e o ponto mais próximo
    final distance = (circleCenter - closestPoint).distance;

    // Verificar se a distância é menor que o raio
    return distance < circleRadius;
  }

  // Função auxiliar para limitar um valor entre min e max
  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
