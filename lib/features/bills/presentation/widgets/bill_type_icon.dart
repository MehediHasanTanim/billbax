import 'package:flutter/material.dart';

import '../../../../core/constants/utility_types.dart';

class BillTypeIcon extends StatelessWidget {
  const BillTypeIcon({super.key, required this.type, this.color});

  final UtilityType type;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      switch (type) {
        UtilityType.desco || UtilityType.dpdc => Icons.bolt,
        UtilityType.wasa => Icons.water_drop,
        UtilityType.titas => Icons.local_fire_department,
        UtilityType.internet => Icons.wifi,
        UtilityType.btcl => Icons.phone,
      },
      color: color,
    );
  }
}
