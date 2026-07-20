import 'package:flutter/material.dart';
import 'package:oil_gid/core/location/app_location_service.dart';
import 'package:oil_gid/pages/onboarding/permission_intro_scaffold.dart';

class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LocationPermissionPage> createState() =>
      _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    await AppLocationService.instance.ensureLocation();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionIntroScaffold(
      icon: Icons.location_on_outlined,
      title: 'Показывать магазины рядом с вами',
      description:
          'Разрешите доступ к геолокации, чтобы мы могли отсортировать '
          'магазины по расстоянию и показать ближайшие к вам.',
      isLoading: _requesting,
      onAllow: _requestPermission,
      onSkip: widget.onDone,
    );
  }
}
