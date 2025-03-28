// lib/entities/explosion.dart
import 'package:flutter/material.dart';

class Explosion {
  Offset position;
  double radius;
  double maxRadius;
  double opacity;
  bool isDone;
  bool isSpecialEffect;
  Color color;

  // Velocidade de crescimento e desvanecimento
  double growthRate;
  double fadeRate;

  Explosion({
    required this.position,
    this.radius = 10,
    this.maxRadius = 40,
    this.opacity = 1.0,
    this.isDone = false,
    this.growthRate = 2.0,
    this.fadeRate = 0.05,
    this.isSpecialEffect = false,
    Color? color,
  }) : color = color ?? Colors.orange;

  void update() {
    // Aumentar tamanho
    radius += growthRate;

    // Reduzir opacidade
    opacity -= fadeRate;

    // Verificar se a explosão acabou
    if (opacity <= 0 || radius >= maxRadius) {
      isDone = true;
      opacity = 0;
    }
  }
}
