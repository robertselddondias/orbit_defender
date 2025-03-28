import 'package:flutter/material.dart';
import 'package:orbit_defender/entities/special_ability.dart';
import 'package:orbit_defender/manager/ability_manager.dart';
import 'package:orbit_defender/ui/widgets/ability_button.dart';
import 'package:orbit_defender/utils/responsive_utils.dart';

class AbilitiesPanel extends StatelessWidget {
  final Function(SpecialAbilityType) onAbilityActivated;

  const AbilitiesPanel({
    Key? key,
    required this.onAbilityActivated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ResponsiveUtils responsive = ResponsiveUtils(context: context);
    final AbilityManager abilityManager = AbilityManager();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.dp(8),
        vertical: responsive.dp(4),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(responsive.dp(30)),
        border: Border.all(
          color: Colors.blueGrey.shade700,
          width: responsive.dp(1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: abilityManager.selectedAbilities.map((ability) {
          return AbilityButton(
            type: ability.type,
            onActivate: () {
              if (abilityManager.activateAbility(ability.type)) {
                onAbilityActivated(ability.type);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
