import 'package:flutter/material.dart';

import 'icon_registry.dart';

class ExpenseCategory {
  final int id;
  final String name;
  final String iconKey;
  final String colorHex;
  final bool isDefault;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    this.isDefault = false,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData get icon => iconRegistry[iconKey] ?? Icons.label_outline;
}
