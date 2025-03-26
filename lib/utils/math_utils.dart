import 'dart:math' as math;

import 'package:flutter/material.dart';

extension OffsetExtension on Offset {
  // Normaliza um vetor (mantém a direção, mas o tamanho se torna 1)
  Offset normalized() {
    if (dx == 0 && dy == 0) return Offset.zero;
    final length = distance;
    return Offset(dx / length, dy / length);
  }

  // Calcula o ângulo entre dois vetores
  double angleTo(Offset other) {
    return math.atan2(other.dy - dy, other.dx - dx);
  }

  // Rotaciona um vetor por um ângulo em radianos
  Offset rotated(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(dx * cos - dy * sin, dx * sin + dy * cos);
  }
}

// Calcula uma posição na borda da tela baseada em um ângulo
Offset getPositionOnScreenEdge(Size screenSize, double angle) {
  final centerX = screenSize.width / 2;
  final centerY = screenSize.height / 2;

  final width = screenSize.width;
  final height = screenSize.height;

  // Determinar em qual borda o ângulo cruza
  if (angle < 0) angle += 2 * math.pi;

  // Tangente do ângulo
  final tan = math.tan(angle);

  Offset position;

  // Ângulos próximos de 0, PI/2, PI, 3PI/2 requerem tratamento especial
  if (angle < math.pi / 4 || angle > 7 * math.pi / 4) {
    // Direita
    position = Offset(width, centerY + tan * (width - centerX));
  } else if (angle < 3 * math.pi / 4) {
    // Baixo
    position = Offset(centerX + (height - centerY) / tan, height);
  } else if (angle < 5 * math.pi / 4) {
    // Esquerda
    position = Offset(0, centerY - tan * centerX);
  } else {
    // Topo
    position = Offset(centerX - centerY / tan, 0);
  }

  return position;
}

// Converte de graus para radianos
double degreesToRadians(double degrees) {
  return degrees * math.pi / 180;
}

// Converte de radianos para graus
double radiansToDegrees(double radians) {
  return radians * 180 / math.pi;
}
