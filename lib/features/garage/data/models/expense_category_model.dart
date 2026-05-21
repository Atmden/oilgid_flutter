import '../../../../core/utils/parsers.dart';
import '../../domain/entities/expense_category.dart';

class ExpenseCategoryModel extends ExpenseCategory {
  const ExpenseCategoryModel({
    required super.id,
    required super.name,
    required super.iconKey,
    required super.colorHex,
    super.isDefault,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: toIntSafe(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? 'more_horiz',
      colorHex: json['color_hex']?.toString() ?? '#546E7A',
      isDefault: json['is_default'] == true,
    );
  }
}
