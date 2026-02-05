import '../../domain/entities/oil_type.dart';
import 'oil_item_model.dart';

class OilTypeModel extends OilType {
  OilTypeModel({
    required super.oilTypeId,
    required super.oilTypeTitle,
    required super.oilTypeIcon,
    required super.oilTypeVolume,
    required super.oilTypeDescription,
    required super.items,
  });

  factory OilTypeModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OilItemModel.fromJson)
        .toList();

    return OilTypeModel(
      oilTypeId: json['oil_type_id'] ?? 0,
      oilTypeTitle: json['oil_type_title'] ?? '',
      oilTypeIcon: json['oil_type_icon'] ?? '',
      oilTypeVolume: json['oil_type_volume'] ?? '',
      oilTypeDescription: json['oil_type_description'] ?? '',
      items: items,
    );
  }
}
