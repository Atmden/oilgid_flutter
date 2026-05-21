# Задача для Flutter-агента: поддержка цен по объёмам канистр

## Контекст

Бэкенд приложения OILGID добавил поддержку цен масел с разбивкой по объёмам канистр (1 л, 4 л и т.д.).
Ранее API возвращало одно поле `price` на магазин. Теперь возвращается массив `prices`.

## Изменения в API

### Эндпоинты, которые изменились

- `GET /api/oils/{oil_id}/shops` — список магазинов, где продаётся масло
- `GET /api/oils/{oil_id}/markers` — те же магазины с геолокацией

### Старый формат ответа (каждый объект магазина содержал)

```json
{
  "id": 1,
  "name": "Магазин",
  "price": 5000,
  "quantity": 3,
  ...
}
```

### Новый формат ответа

```json
{
  "id": 1,
  "name": "Магазин",
  "price": null,
  "quantity": null,
  "prices": [
    {
      "volume_id": 1,
      "label": "1 л",
      "value": "1.000",
      "unit": "л",
      "price": "5000.00",
      "quantity": 10
    },
    {
      "volume_id": 2,
      "label": "4 л",
      "value": "4.000",
      "unit": "л",
      "price": "18000.00",
      "quantity": 3
    }
  ],
  ...
}
```

**Поля `price` и `quantity` теперь всегда `null`** — они оставлены для совместимости, не используй их.

## Что нужно сделать во Flutter

### 1. Модель данных

Добавь новую модель (или обнови существующую) `ShopPrice`:
```dart
class ShopPrice {
  final int volumeId;
  final String label;   // "1 л", "4 л" — готовая строка для отображения
  final String value;   // "1.000" — числовое значение объёма
  final String unit;    // "л", "мл", "кг"
  final double? price;
  final int? quantity;
}
```

Обнови модель магазина (`Shop` или `OilShop`): вместо `double? price` и `int? quantity` добавь `List<ShopPrice> prices`.

### 2. Парсинг JSON

```dart
factory ShopPrice.fromJson(Map<String, dynamic> json) => ShopPrice(
  volumeId: json['volume_id'],
  label: json['label'],
  value: json['value'],
  unit: json['unit'],
  price: json['price'] != null ? double.parse(json['price'].toString()) : null,
  quantity: json['quantity'],
);
```

В модели магазина:
```dart
prices: (json['prices'] as List<dynamic>)
    .map((e) => ShopPrice.fromJson(e))
    .toList(),
```

### 3. UI — отображение цен

#### Вариант отображения в карточке магазина

Если у магазина один объём — показываем просто цену и объём.
Если несколько — показываем список строк "1 л — 5 000 ₸".

Пример виджета:
```dart
// Если prices пустой
if (shop.prices.isEmpty) {
  return Text('Цена не указана');
}

// Если один объём
if (shop.prices.length == 1) {
  final p = shop.prices.first;
  return Text('${p.label} — ${formatPrice(p.price)} ₸');
}

// Несколько объёмов — список
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: shop.prices.map((p) =>
    Text('${p.label} — ${formatPrice(p.price)} ₸')
  ).toList(),
)
```

#### На экране детали масла (список магазинов)

Рекомендуется показывать все доступные объёмы с ценами. Если пользователь ищет конкретный объём — можно добавить фильтр.

### 4. Экран маркеров (карта)

При тапе на маркер магазина — показывать в bottom sheet или popup все объёмы с ценами.
Мин. цену можно вычислить как `prices.map((p) => p.price).whereNotNull().reduce(min)`.

### 5. Обратная совместимость

Поля `price` и `quantity` в JSON теперь всегда `null`. Если старый код читает `json['price']` — он получит null. Убедись, что это не вызывает краш (используй `?.` и дефолтные значения).

## Файлы, которые вероятно нужно изменить

- Модель магазина / OilShop DTO
- Модель ShopPrice (создать новую)
- Виджет карточки магазина на экране детали масла
- Виджет маркера / bottom sheet на карте
- Любое место, где читался `shop.price` — заменить на работу с `shop.prices`

## API-контракт (структура полного ответа)

```json
{
  "status": true,
  "data": [
    {
      "id": 1,
      "name": "string",
      "address": "string",
      "city": "string | null",
      "contacts": "string | null",
      "website": "string | null",
      "working_hours": "string | null",
      "phone": "string | null",
      "whatsapp_phone": "string | null",
      "email": "string | null",
      "online_purchase_available": true,
      "price": null,
      "quantity": null,
      "prices": [
        {
          "volume_id": 1,
          "label": "1 л",
          "value": "1.000",
          "unit": "л",
          "price": "5000.00",
          "quantity": 10
        }
      ],
      "distance_m": 1200,
      "lat": 51.123,
      "lng": 71.456
    }
  ]
}
```
