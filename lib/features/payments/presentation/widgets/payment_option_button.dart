import 'package:flutter/material.dart';

class PaymentOptionButton extends StatelessWidget {
  const PaymentOptionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconData,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? iconData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(iconData ?? Icons.open_in_new),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
