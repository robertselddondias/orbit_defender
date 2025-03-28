import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/special_ability.dart';
import 'package:orbit_defender/manager/ability_manager.dart';
import 'package:orbit_defender/utils/responsive_utils.dart';

class AbilityButton extends StatefulWidget {
  final SpecialAbilityType type;
  final VoidCallback onActivate;

  const AbilityButton({
    Key? key,
    required this.type,
    required this.onActivate,
  }) : super(key: key);

  @override
  State<AbilityButton> createState() => _AbilityButtonState();
}

class _AbilityButtonState extends State<AbilityButton> with SingleTickerProviderStateMixin {
  late final AbilityManager _abilityManager;
  late SpecialAbility _ability;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _abilityManager = AbilityManager();

    // Encontrar a habilidade correspondente
    _ability = _abilityManager.selectedAbilities.firstWhere(
          (ability) => ability.type == widget.type,
    );

    // Configurar animação de pulso para quando a habilidade estiver pronta
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);

    // Adicionar listener para mudanças no estado da habilidade
    _abilityManager.addListener(_handleAbilityStateChanged);
  }

  void _handleAbilityStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _abilityManager.removeListener(_handleAbilityStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ResponsiveUtils responsive = ResponsiveUtils(context: context);

    // Determinar o estado da habilidade
    final bool isInCooldown = _ability.isInCooldown;
    final double cooldownPercentage = _ability.cooldownPercentage;
    final bool isActive = _ability.isActive;

    return GestureDetector(
      onTap: () {
        if (!isInCooldown && !isActive) {
          widget.onActivate();
        }
      },
      child: Container(
        width: responsive.dp(60),
        height: responsive.dp(60),
        margin: EdgeInsets.all(responsive.dp(4)),
        child: Stack(
          children: [
            // Botão principal
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isInCooldown ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? _ability.primaryColor
                          : (isInCooldown ? Colors.grey.shade800 : Colors.grey.shade700),
                      border: Border.all(
                        color: isActive
                            ? _ability.primaryColor.withOpacity(0.8)
                            : (isInCooldown ? Colors.grey.shade600 : _ability.primaryColor),
                        width: responsive.dp(2),
                      ),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: _ability.primaryColor.withOpacity(0.5),
                          blurRadius: responsive.dp(10),
                          spreadRadius: responsive.dp(2),
                        )
                      ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Center(
                        child: Icon(
                          _getIconForAbilityType(_ability.type),
                          color: isActive || !isInCooldown ? Colors.white : Colors.grey.shade400,
                          size: responsive.dp(28),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Indicador de cooldown
            if (isInCooldown)
              CircularProgressIndicator(
                value: cooldownPercentage,
                strokeWidth: responsive.dp(4),
                backgroundColor: Colors.grey.shade800,
                color: _ability.primaryColor.withOpacity(0.7),
              ),

            // Tempo restante de cooldown
            if (isInCooldown)
              Center(
                child: Text(
                  '${_ability.remainingCooldown.inSeconds}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.dp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Mapear cada tipo de habilidade para um ícone
  IconData _getIconForAbilityType(SpecialAbilityType type) {
    switch (type) {
      case SpecialAbilityType.superShot:
        return Icons.flash_on;
      case SpecialAbilityType.areaBomb:
        return Icons.blur_circular;
      case SpecialAbilityType.timeWarp:
        return Icons.hourglass_empty;
      case SpecialAbilityType.magnetField:
        return Icons.switch_right;
      case SpecialAbilityType.rapidFire:
        return Icons.speed;
    }
  }
}
