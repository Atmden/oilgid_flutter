# Локальная копия yandex_mapkit 4.2.1 (патч OILGID)

Исходник: https://pub.dev/packages/yandex_mapkit/versions/4.2.1
(sha256 архива `30a6f7e1d99871338071425a389c53491018602ee24be16e9cf63e640d57dda1`, совпадает с прежним pubspec.lock).
Папка `example/` удалена, остальное без изменений, кроме одной правки ниже.

## Правка
`ios/Classes/lite/ClusterizedPlacemarkCollectionController.swift`, `onClusterAdded`:

```diff
-      let params = result as! [String: Any]
+      guard let params = result as? [String: Any] else {
+        return
+      }
```

## Зачем
Sentry issue 123994814: `SIGABRT: Could not cast value of type 'NSObject' to 'NSDictionary'`.
Падало при нажатии «Показать магазины на карте» (MapScreen): нативная карта присылает
`onClusterAdded` до того, как Dart-контроллер установил обработчик канала (или после dispose).
Flutter возвращает `FlutterMethodNotImplemented` (NSObject), и принудительное приведение роняет приложение.

Апстрим не исправил: в 4.3.0 и master та же строка; PR Unact/yandex_mapkit#341 с этой же правкой
закрыт без слияния (2024-03-29), ранее issue #217.

## При обновлении плагина
Перенести эту правку в новую версию или убрать `dependency_overrides` из pubspec.yaml,
если апстрим её исправит.
