import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oil_gid/features/oils/data/datasources/oil_api.dart';
import 'package:oil_gid/features/oils/data/models/oil_brand_model.dart';
import 'package:oil_gid/features/oils/data/models/oil_item_model.dart';
import 'package:oil_gid/features/oils/presentation/widgets/country_flag.dart';

void main() {
  group('OilBrandModel.countries', () {
    test('парсит страны бренда', () {
      final brand = OilBrandModel.fromJson({
        'id': 112,
        'title': 'MOBIL',
        'description': '',
        'logo': '',
        'countries': [
          {
            'id': 56,
            'iso2': 'DE',
            'iso3': 'DEU',
            'title': 'Германия',
            'title_en': 'Germany',
            'flag_url': 'https://oilgid.kz/flags/de.png',
            'flag_emoji': '🇩🇪',
          },
          {'id': 0, 'title': 'битая запись'},
          'не объект',
        ],
      });

      expect(brand.countries, hasLength(1));
      expect(brand.countries.single.id, 56);
      expect(brand.countries.single.iso2, 'DE');
      expect(brand.countries.single.title, 'Германия');
      expect(brand.countries.single.flagUrl, 'https://oilgid.kz/flags/de.png');
      expect(brand.countries.single.flagEmoji, '🇩🇪');
    });

    test('без ключа countries — пустой список', () {
      final brand = OilBrandModel.fromJson({'id': 1, 'title': 'X'});
      expect(brand.countries, isEmpty);
    });

    test('страны доходят через OilItemModel.brand', () {
      final oil = OilItemModel.fromJson({
        'id': 1,
        'title': 'Mobil 1',
        'brand': {
          'id': 112,
          'title': 'MOBIL',
          'countries': [
            {'id': 241, 'iso2': 'JP', 'title': 'Япония', 'flag_url': '', 'flag_emoji': '🇯🇵'},
          ],
        },
      });
      expect(oil.brand?.countries.single.iso2, 'JP');
    });
  });

  test('CatalogFacetOption парсит флаг для фасета country', () {
    final options = CatalogFacetOption.fromJsonList([
      {
        'id': 56,
        'title': 'Германия',
        'iso2': 'DE',
        'flag_url': 'https://oilgid.kz/flags/de.png',
        'flag_emoji': '🇩🇪',
        'count': 75,
        'selected': true,
      },
      {'id': 3, 'title': '5W-30', 'count': 10, 'selected': false},
    ]);

    expect(options.first.iso2, 'DE');
    expect(options.first.flagUrl, 'https://oilgid.kz/flags/de.png');
    expect(options.first.count, 75);
    expect(options.first.selected, isTrue);
    expect(options.last.flagUrl, isNull);
    expect(options.last.flagEmoji, isNull);
  });

  testWidgets('CountryFlag без URL показывает emoji', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CountryFlag(flagUrl: '', flagEmoji: '🇩🇪')),
      ),
    );
    expect(find.text('🇩🇪'), findsOneWidget);
  });
}
