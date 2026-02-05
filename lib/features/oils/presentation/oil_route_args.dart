import '../domain/entities/oil_item.dart';

class OilSelectionArgs {
  final int modificationId;
  final String? carTitle;
  final String? carSubtitle;
  final String? carLogo;

  OilSelectionArgs({
    required this.modificationId,
    this.carTitle,
    this.carSubtitle,
    this.carLogo,
  });
}

class OilListArgs {
  final int modificationId;
  final int oilTypeId;
  final String oilTypeTitle;
  final String oilTypeVolume;
  final String oilTypeDescription;
  final String? carTitle;
  final List<OilItem>? items;

  OilListArgs({
    required this.modificationId,
    required this.oilTypeId,
    required this.oilTypeTitle,
    required this.oilTypeVolume,
    required this.oilTypeDescription,
    this.carTitle,
    this.items,
  });
}

class OilDetailsArgs {
  final OilItem item;
  final String volume;
  final String description;

  OilDetailsArgs({required this.item, required this.volume, required this.description});
}
