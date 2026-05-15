# CLAUDE.md

Этот файл содержит руководство для Claude Code (claude.ai/code) при работе с данным репозиторием.

## Команды

```bash
flutter pub get          # Установить зависимости
flutter run              # Запустить в режиме отладки
flutter run --release    # Запустить в release-режиме
flutter test             # Запустить тесты (тестов пока нет)
flutter build apk        # Собрать Android APK
flutter build ios        # Собрать iOS
```

## Архитектура

**OilGid** — Flutter-приложение (v1.1.2, SDK ^3.10.3) для поиска моторных масел, нахождения авторизованных магазинов и подбора автомобильных конфигураций. Интерфейс на русском языке.

### Структура

Код расположен в `lib/`:
- `core/` — инфраструктура: API-клиент, диплинки, запуск приложения, хранилище, утилиты
- `features/` — модули по чистой архитектуре: `oils/`, `shops/`, `car_marks/`, `car_models/`, `car_generations/`, `car_configurations/`, `car_modifications/`
- `pages/` — полноэкранные виджеты (18 страниц)
- `includes/` — переиспользуемые карточки и компоненты
- `themes/`, `model/`, `lang/` — тема, устаревшие модели, локализация

Каждый модуль в `features/` делится на три слоя:
- `domain/` — сущности (чистый Dart) + абстрактные интерфейсы репозиториев
- `data/` — реализации репозиториев, API-источники данных, JSON-модели
- `presentation/` — страницы, виджеты, Riverpod-провайдеры

### Управление состоянием: Riverpod

Провайдеры находятся в `lib/features/*/presentation/providers/*provider.dart`. Пагинированные списки используют `AsyncNotifierProvider` с методами `.loadMore()` и `.refresh()`. Простое UI-состояние — `StateProvider`.

### API-слой

- **Клиент:** синглтон Dio в `lib/core/api/dio_client.dart`, базовый URL `https://oilgid.kz/api`
- **Аутентификация:** Bearer-токены добавляются через Dio-интерцептор. Два токена: пользовательский и токен приложения (генерируется при первом запуске через `InitTokenGenerator`)
- **Кэширование:** пакет `cached_query`, TTL 10 минут
- **Хранилище:** FlutterSecureStorage для токенов, SharedPreferences для флага `privacy_accepted`, Hive для выбранных автомобилей пользователя (box: `'user_cars'`)

### Последовательность запуска

`lib/core/startup/startup_controller.dart` выполняется при старте:
1. Инициализация Sentry
2. Firebase + Crashlytics + Analytics
3. Получение или генерация токена приложения
4. Инициализация Hive
5. Загрузка SharedPreferences

Некритичные шаги деградируют gracefully (таймаут/ошибка не блокируют запуск).

### Навигация и диплинки

Именованные маршруты через `Navigator.pushNamed()` с типизированными классами аргументов (например, `ShopPageInput`, `OilDetailsInput`). Диплинки разбираются в `lib/core/deeplink/` и откладываются до принятия политики конфиденциальности.

### Ключевые зависимости

| Назначение | Пакет |
|------------|-------|
| Управление состоянием | flutter_riverpod 3.1.0 |
| HTTP | dio 5.9.0 |
| Карты | yandex_mapkit 4.2.1 |
| Локальная БД | hive |
| Безопасное хранилище | flutter_secure_storage |
| Отслеживание ошибок | sentry_flutter + firebase_crashlytics |
| Аналитика | firebase_analytics |
| Геолокация | geolocator 14.0.2 |
| Проверка обновлений | upgrader 12.5.0 |
