import 'package:geolocator/geolocator.dart';

/// Кэширует геопозицию пользователя и однократно запрашивает разрешение
/// на геолокацию за всё время жизни приложения (см. [ensureLocation]).
class AppLocationService {
  AppLocationService._();

  static final AppLocationService instance = AppLocationService._();

  Position? _position;
  Future<Position?>? _pendingFetch;

  Position? get cachedPosition => _position;

  Future<Position?> ensureLocation() {
    if (_position != null) return Future.value(_position);
    return _pendingFetch ??= _fetch();
  }

  Future<Position?> _fetch() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Нет свежего фикса (таймаут, помещение) — берём последнюю известную
        // позицию, чтобы магазины всё равно шли от ближнего к дальнему.
        position = await _lastKnownPosition();
      }
      _position = position;
      return position;
    } catch (_) {
      return null;
    } finally {
      _pendingFetch = null;
    }
  }

  Future<Position?> _lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}
