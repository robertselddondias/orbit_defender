// lib/entities/enemy.dart
import 'dart:math';

import 'package:flutter/material.dart';

enum EnemyType {
  normalAsteroid,
  fastAsteroid,
}

class Enemy {
  Offset position;
  Offset direction;
  double speed;
  double radius;
  EnemyType type;
  double rotation;
  int pointValue;

  // Rotação do asteroide
  double rotationSpeed;

  Enemy({
    required this.position,
    required this.direction,
    required this.speed,
    required this.radius,
    required this.type,
    required this.rotation,
    required this.pointValue,
  }) : rotationSpeed = (Random().nextDouble() * 0.1) - 0.05;

  void update({double speedMultiplier = 1.0}) {
    // Mover inimigo, possivelmente com velocidade reduzida devido a habilidades
    position = position + direction * (speed * speedMultiplier);

    // Rotacionar
    rotation += rotationSpeed;
  }
}
