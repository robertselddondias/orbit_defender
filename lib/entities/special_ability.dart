import 'package:flutter/material.dart';

enum SpecialAbilityType {
  superShot,    // Tiro poderoso que destrói vários inimigos
  areaBomb,     // Bomba que afeta todos os inimigos na tela
  timeWarp,     // Desacelera todos os inimigos por alguns segundos
  magnetField,  // Atrai todos os power-ups na tela
  rapidFire,    // Disparos rápidos por um curto período
}

class SpecialAbility {
  final SpecialAbilityType type;
  final String name;
  final String description;
  final String iconPath;
  final Duration cooldownDuration;
  final Duration effectDuration;
  final Color primaryColor;

  // Estado da habilidade
  DateTime? _lastUsedTime;
  bool _isActive = false;

  SpecialAbility({
    required this.type,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.cooldownDuration,
    required this.effectDuration,
    required this.primaryColor,
  });

  bool get isInCooldown {
    if (_lastUsedTime == null) return false;
    final timeSinceLastUse = DateTime.now().difference(_lastUsedTime!);
    return timeSinceLastUse < cooldownDuration;
  }

  Duration get remainingCooldown {
    if (!isInCooldown) return Duration.zero;
    final timeSinceLastUse = DateTime.now().difference(_lastUsedTime!);
    return cooldownDuration - timeSinceLastUse;
  }

  double get cooldownPercentage {
    if (!isInCooldown) return 0.0;
    return 1.0 - (remainingCooldown.inMilliseconds / cooldownDuration.inMilliseconds);
  }

  bool get isActive => _isActive;

  void activate() {
    _lastUsedTime = DateTime.now();
    _isActive = true;

    // Desativar após a duração do efeito
    Future.delayed(effectDuration, () {
      _isActive = false;
    });
  }

  // Cria instâncias predefinidas das habilidades
  static SpecialAbility createSuperShot() {
    return SpecialAbility(
      type: SpecialAbilityType.superShot,
      name: 'Tiro Poderoso',
      description: 'Dispara um projétil massivo capaz de destruir vários inimigos.',
      iconPath: 'assets/images/abilities/super_shot.png',
      cooldownDuration: const Duration(seconds: 12),
      effectDuration: const Duration(milliseconds: 500), // Efeito quase instantâneo
      primaryColor: Colors.amber,
    );
  }

  static SpecialAbility createAreaBomb() {
    return SpecialAbility(
      type: SpecialAbilityType.areaBomb,
      name: 'Bomba de Área',
      description: 'Explode e causa dano a todos os inimigos na tela.',
      iconPath: 'assets/images/abilities/area_bomb.png',
      cooldownDuration: const Duration(seconds: 20),
      effectDuration: const Duration(milliseconds: 1500),
      primaryColor: Colors.redAccent,
    );
  }

  static SpecialAbility createTimeWarp() {
    return SpecialAbility(
      type: SpecialAbilityType.timeWarp,
      name: 'Distorção Temporal',
      description: 'Desacelera todos os inimigos por um curto período.',
      iconPath: 'assets/images/abilities/time_warp.png',
      cooldownDuration: const Duration(seconds: 25),
      effectDuration: const Duration(seconds: 5),
      primaryColor: Colors.purpleAccent,
    );
  }

  static SpecialAbility createMagnetField() {
    return SpecialAbility(
      type: SpecialAbilityType.magnetField,
      name: 'Campo Magnético',
      description: 'Atrai todos os power-ups na tela em sua direção.',
      iconPath: 'assets/images/abilities/magnet_field.png',
      cooldownDuration: const Duration(seconds: 15),
      effectDuration: const Duration(seconds: 3),
      primaryColor: Colors.blueAccent,
    );
  }

  static SpecialAbility createRapidFire() {
    return SpecialAbility(
      type: SpecialAbilityType.rapidFire,
      name: 'Tiro Rápido',
      description: 'Dispara projéteis rapidamente por um curto período.',
      iconPath: 'assets/images/abilities/rapid_fire.png',
      cooldownDuration: const Duration(seconds: 18),
      effectDuration: const Duration(seconds: 4),
      primaryColor: Colors.greenAccent,
    );
  }

  void forceActivate() {
    _isActive = true;
    _lastUsedTime = DateTime.now();

    // Desativar após a duração do efeito
    Future.delayed(effectDuration, () {
      _isActive = false;
    });
  }
}

