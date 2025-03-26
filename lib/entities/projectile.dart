// projectile.dart
import 'package:flutter/material.dart';

class Projectile {
  Offset position;
  Offset direction;
  double speed;
  double radius;

  Projectile({
    required this.position,
    required this.direction,
    required this.speed,
    required this.radius,
  });

  void update() {
    position = position + direction * speed;
  }
}
