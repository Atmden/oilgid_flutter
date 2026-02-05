import 'oil_item.dart';

class OilType {
  final int oilTypeId;
  final String oilTypeTitle;
  final String oilTypeIcon;
  final String oilTypeVolume;
  final String oilTypeDescription;
  final List<OilItem> items;

  OilType({
    required this.oilTypeId,
    required this.oilTypeTitle,
    required this.oilTypeIcon,
    required this.oilTypeVolume,
    required this.oilTypeDescription,
    required this.items,
  });

  @override
  String toString() {
    return 'OilType(oilTypeId: $oilTypeId, oilTypeTitle: $oilTypeTitle, oilTypeIcon: $oilTypeIcon, oilTypeVolume: $oilTypeVolume, oilTypeDescription: $oilTypeDescription, items: $items)';
  }
}
