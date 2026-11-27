import '../../domain/entities/oil_brand.dart';
import 'oil_country_model.dart';

class OilBrandModel extends OilBrand {
  OilBrandModel({
    required super.id,
    required super.title,
    required super.description,
    required super.logo,
    super.countries,
  });

  factory OilBrandModel.fromJson(Map<String, dynamic> json) {
    return OilBrandModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      countries: OilCountryModel.fromJsonList(json['countries']),
    );
  }
}
