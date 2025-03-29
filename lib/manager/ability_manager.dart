import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/special_ability.dart';

class AbilityManager {
  // Singleton
  static final AbilityManager _instance = AbilityManager._internal();
  factory AbilityManager() => _instance;
  AbilityManager._internal();

  // Liste de habilidades disponíveis
  final List<SpecialAbility> _availableAbilities = [];

  // Habilidades selecionadas para uso atual (no máximo 3)
  final List<SpecialAbility> _selectedAbilities = [];

  // Listeners para mudanças no estado das habilidades
  final List<VoidCallback> _listeners = [];

  // Inicializar o gerenciador
  void initialize() {
    // Limpar seleções anteriores
    _selectedAbilities.clear();

    // Criar todas as habilidades disponíveis
    _availableAbilities.clear();
    _availableAbilities.addAll([
      SpecialAbility.createSuperShot(),
      SpecialAbility.createAreaBomb(),
      SpecialAbility.createTimeWarp(),
      SpecialAbility.createMagnetField(),
      SpecialAbility.createRapidFire(),
    ]);

    // Por padrão, selecionar as 3 primeiras habilidades
    selectDefaultAbilities();
  }

  // Selecionar habilidades padrão
  void selectDefaultAbilities() {
    _selectedAbilities.clear();

    // Adicionar 3 habilidades padrão (ou menos se não houver 3 disponíveis)
    final int count = _availableAbilities.length > 3 ? 3 : _availableAbilities.length;
    for (int i = 0; i < count; i++) {
      _selectedAbilities.add(_availableAbilities[i]);
    }

    _notifyListeners();
  }

  // Selecionar uma habilidade específica
  bool selectAbility(SpecialAbilityType type) {
    // Verificar se a habilidade já está selecionada
    if (_selectedAbilities.any((ability) => ability.type == type)) {
      return false;
    }

    // Verificar se já temos 3 habilidades selecionadas
    if (_selectedAbilities.length >= 3) {
      return false;
    }

    // Encontrar a habilidade pelo tipo
    final ability = _availableAbilities.firstWhere(
          (ability) => ability.type == type,
      orElse: () => throw Exception('Habilidade não encontrada: $type'),
    );

    // Adicionar à lista de selecionadas
    _selectedAbilities.add(ability);
    _notifyListeners();
    return true;
  }

  // Remover uma habilidade da seleção
  bool unselectAbility(SpecialAbilityType type) {
    final initialLength = _selectedAbilities.length;
    _selectedAbilities.removeWhere((ability) => ability.type == type);

    if (_selectedAbilities.length != initialLength) {
      _notifyListeners();
      return true;
    }
    return false;
  }

  // Ativar uma habilidade
  bool activateAbility(SpecialAbilityType type) {
    // Encontrar a habilidade entre as selecionadas
    final ability = _selectedAbilities.firstWhere(
          (ability) => ability.type == type,
      orElse: () => throw Exception('Habilidade não selecionada: $type'),
    );

    // Verificar se está em cooldown
    if (ability.isInCooldown) {
      return false;
    }

    // Ativar a habilidade
    ability.activate();
    _notifyListeners();

    // Programar notificação quando terminar o cooldown
    Future.delayed(ability.cooldownDuration, () {
      _notifyListeners();
    });

    return true;
  }

  // Verificar se uma habilidade está ativa
  bool isAbilityActive(SpecialAbilityType type) {
    return _selectedAbilities.any((ability) => ability.type == type && ability.isActive);
  }

  // Obter informações sobre o cooldown de uma habilidade
  double getAbilityCooldownPercentage(SpecialAbilityType type) {
    final ability = _selectedAbilities.firstWhere(
          (ability) => ability.type == type,
      orElse: () => throw Exception('Habilidade não selecionada: $type'),
    );

    return ability.cooldownPercentage;
  }

  // Obter o tempo restante de cooldown em segundos
  int getAbilityRemainingCooldownSeconds(SpecialAbilityType type) {
    final ability = _selectedAbilities.firstWhere(
          (ability) => ability.type == type,
      orElse: () => throw Exception('Habilidade não selecionada: $type'),
    );

    return ability.remainingCooldown.inSeconds;
  }

  // Obter todas as habilidades disponíveis
  List<SpecialAbility> get availableAbilities => List.unmodifiable(_availableAbilities);

  // Obter habilidades selecionadas
  List<SpecialAbility> get selectedAbilities => List.unmodifiable(_selectedAbilities);

  // Gerenciamento de listeners
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Limpeza
  void dispose() {
    _listeners.clear();
    _selectedAbilities.clear();
    _availableAbilities.clear();
  }
}
