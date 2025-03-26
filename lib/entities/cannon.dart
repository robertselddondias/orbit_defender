// cannon.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/power_up_type.dart';

class Cannon {
  Offset position;
  double radius;

  final Map<PowerUpType, DateTime> _activePowerUps = {};

  Cannon({
    required this.position,
    required this.radius,
  });

  void reset() {
    _activePowerUps.clear();
  }

  void activatePowerUp(PowerUpType type, {required Duration duration}) {
    final expiryTime = DateTime.now().add(duration);
    _activePowerUps[type] = expiryTime;

    // Configurar um timer para remover o power-up após a duração
    Timer(duration, () {
      _activePowerUps.remove(type);
    });
  }

  bool hasPowerUp(PowerUpType type) {
    if (!_activePowerUps.containsKey(type)) return false;

    final expiryTime = _activePowerUps[type]!;
    return DateTime.now().isBefore(expiryTime);
  }
}
