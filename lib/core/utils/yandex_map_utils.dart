import 'package:geolocator/geolocator.dart';

abstract class YandexMapUtils {
  Future<AppLatLong> getCurrentLocation();

  Future<bool> requestPermission();

  Future<bool> checkPermission();
}

class AppLatLong {
  final double lat;
  final double lng;

  const AppLatLong({required this.lat, required this.lng});
}

class AqtobeLocation extends AppLatLong {
  const AqtobeLocation({super.lat = 50.300377, super.lng = 57.154555});
}

class LocationServices implements YandexMapUtils {
  final defLocation = AqtobeLocation();

  @override
  Future<AppLatLong> getCurrentLocation() async {
    return Geolocator.getCurrentPosition()
        .then((value) {
          return AppLatLong(lat: value.latitude, lng: value.longitude);
        })
        .catchError((_) => defLocation);
  }

  @override
  Future<bool> requestPermission() {
    return Geolocator.requestPermission()
        .then(
          (value) =>
              value == LocationPermission.always ||
              value == LocationPermission.whileInUse,
        )
        .catchError((_) => false);
  }

  @override
  Future<bool> checkPermission() {
    return Geolocator.checkPermission()
        .then(
          (value) =>
              value == LocationPermission.always ||
              value == LocationPermission.whileInUse,
        )
        .catchError((_) => false);
  }
}
