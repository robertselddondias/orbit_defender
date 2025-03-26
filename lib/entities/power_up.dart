// power_up.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/power_up_type.dart';
import 'package:orbit_defender/utils/math_utils.dart';


class PowerUp {
  Offset position;
  Offset direction;
  double speed;
  double radius;
  PowerUpType type;
  bool isLevelUpBonus; // Nova propriedade
  double pulseValue; // Para efeito de pulsação
  double rotationAngle;

  // Nova propriedade para rastrear atração
  bool isAttracted = false;

  PowerUp({
    required this.position,
    required this.direction,
    required this.speed,
    required this.radius,
    required this.type,
    this.isLevelUpBonus = false,
    this.pulseValue = 0.0,
    this.rotationAngle = 0.0,
  });

  void update() {
    position = position + direction * speed;

    // Efeito de pulsação para power-ups de level up
    if (isLevelUpBonus) {
      pulseValue += 0.1; // Incremento para o efeito de pulsação
      rotationAngle += 0.05; // Incremento para rotação
    }
  }

  // Novo método para atualizar quando atraído para o canhão
  void updateAttraction(Offset targetPosition, double attractionSpeed) {
    if (isAttracted) {
      // Calcular direção para o canhão
      final directionToTarget = (targetPosition - position).normalized();

      // Aumentar velocidade gradualmente
      speed = min(speed + 0.2, attractionSpeed);

      // Atualizar direção para se mover em direção ao canhão
      direction = directionToTarget;

      // Atualizar posição
      position = position + direction * speed;
    } else {
      // Comportamento normal
      update();
    }
  }

  double get currentRadius {
    if (isLevelUpBonus) {
      // Oscilar entre 90% e 110% do raio
      return radius * (0.9 + 0.2 * (sin(pulseValue) + 1) / 2);
    }
    return radius;
  }
}
