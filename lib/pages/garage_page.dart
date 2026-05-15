import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/api/subscription_api.dart';
import 'package:oil_gid/features/garage/domain/entities/user_car.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  final _garageApi = AppApi().garageApi;
  final _subscriptionApi = SubscriptionApi();

  bool _isLoading = true;
  bool? _hasAccess;
  List<UserCar> _cars = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hasAccess = await _subscriptionApi.hasEntitlement('garage_book');
      if (!mounted) return;
      if (!hasAccess) {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }
      final cars = await _garageApi.getCars();
      if (!mounted) return;
      setState(() {
        _hasAccess = true;
        _cars = cars;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openCar(UserCar car) {
    Navigator.pushNamed(
      context,
      '/garage/car',
      arguments: GarageCarPageArgs(carId: car.id, car: car),
    ).then((_) => _load());
  }

  void _addCar() {
    Navigator.pushNamed(
      context,
      '/garage/car/form',
      arguments: const GarageCarFormArgs(),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(title: 'Гараж'),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: _hasAccess == true
          ? FloatingActionButton.extended(
              onPressed: _addCar,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить авто'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    if (_hasAccess == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.garage_outlined, size: 72, color: Colors.black26),
              const SizedBox(height: 24),
              const Text(
                'Гараж',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Функция «Гараж» доступна по подписке. Оформите подписку, чтобы хранить историю обслуживания своих автомобилей.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/paywall')
                    .then((_) => _load()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Оформить подписку',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_car_outlined, size: 72, color: Colors.black26),
              const SizedBox(height: 24),
              const Text(
                'Нет автомобилей',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавьте автомобиль, чтобы вести историю обслуживания.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addCar,
                icon: const Icon(Icons.add),
                label: const Text('Добавить автомобиль'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _cars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _CarCard(
          car: _cars[index],
          onTap: () => _openCar(_cars[index]),
        ),
      ),
    );
  }
}

class _CarLogo extends StatelessWidget {
  final String? url;
  const _CarLogo({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return SizedBox(
        width: 44,
        height: 44,
        child: CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.contain,
          placeholder: (_, __) => const _FallbackCarIcon(),
          errorWidget: (_, __, ___) => const _FallbackCarIcon(),
        ),
      );
    }
    return const _FallbackCarIcon();
  }
}

class _FallbackCarIcon extends StatelessWidget {
  const _FallbackCarIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: Icon(Icons.directions_car, size: 36, color: AppColors.primarySoft),
    );
  }
}

class _CarCard extends StatelessWidget {
  final UserCar car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _CarLogo(url: car.markLogo),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (car.year != null) ...[
                        const Icon(Icons.calendar_today, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          '${car.year}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (car.mileage != null) ...[
                        const Icon(Icons.speed, size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          '${car.mileage} км',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                  if (car.plateNumber != null && car.plateNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      car.plateNumber!,
                      style: const TextStyle(fontSize: 13, color: Colors.black45),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
