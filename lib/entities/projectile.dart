// lib/entities/projectile.dart
import 'package:flutter/material.dart';

class Projectile {
  Offset position;
  Offset direction;
  double speed;
  double radius;
  int damage;
  bool isSuperShot;
  Color color;

  Projectile({
    required this.position,
    required this.direction,
    required this.speed,
    required this.radius,
    this.damage = 1,
    this.isSuperShot = false,
    this.color = Colors.yellow,
  });

  void update() {
    position = position + direction * speed;
  }
}
