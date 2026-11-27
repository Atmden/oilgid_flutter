import '../../domain/entities/oil_country.dart';

class OilCountryModel extends OilCountry {
  const OilCountryModel({
    required super.id,
    required super.iso2,
    required super.title,
    required super.flagUrl,
    required super.flagEmoji,
  });

  factory OilCountryModel.fromJson(Map<String, dynamic> json) {
    return OilCountryModel(
      id: json['id'] is int ? json['id'] as int : 0,
      iso2: json['iso2']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      flagUrl: json['flag_url']?.toString() ?? '',
      flagEmoji: json['flag_emoji']?.toString() ?? '',
    );
  }

  static List<OilCountry> fromJsonList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(OilCountryModel.fromJson)
        .where((country) => country.id != 0)
        .toList();
  }
}
