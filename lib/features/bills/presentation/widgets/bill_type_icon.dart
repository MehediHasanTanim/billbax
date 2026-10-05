import 'package:flutter/material.dart';

import '../../../../core/constants/utility_types.dart';

/// Placeholder — implemented in Phase 2.
class BillTypeIcon extends StatelessWidget {
  const BillTypeIcon({super.key, required this.type});

  final UtilityType type;

  @override
  Widget build(BuildContext context) {
    return Icon(switch (type) {
      UtilityType.desco || UtilityType.dpdc => Icons.bolt,
      UtilityType.wasa => Icons.water_drop,
      UtilityType.titas => Icons.local_fire_department,
      UtilityType.internet => Icons.wifi,
      UtilityType.btcl => Icons.phone,
    });
  }
}
