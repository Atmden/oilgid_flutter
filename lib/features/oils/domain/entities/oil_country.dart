/// Страна бренда масла (ISO 3166-1).
class OilCountry {
  final int id;
  final String iso2;
  final String title;
  final String flagUrl;
  final String flagEmoji;

  const OilCountry({
    required this.id,
    required this.iso2,
    required this.title,
    required this.flagUrl,
    required this.flagEmoji,
  });
}
