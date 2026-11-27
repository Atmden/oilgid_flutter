import 'oil_country.dart';

class OilBrand {
  final int id;
  final String title;
  final String description;
  final String logo;
  final List<OilCountry> countries;

  OilBrand({
    required this.id,
    required this.title,
    required this.description,
    required this.logo,
    this.countries = const [],
  });
}
