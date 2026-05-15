import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/garage/domain/entities/service_record.dart';
import 'package:oil_gid/features/garage/domain/entities/user_car.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageCarPage extends StatefulWidget {
  const GarageCarPage({super.key});

  @override
  State<GarageCarPage> createState() => _GarageCarPageState();
}

class _GarageCarPageState extends State<GarageCarPage> {
  final _garageApi = AppApi().garageApi;

  late GarageCarPageArgs _args;
  bool _initialized = false;

  UserCar? _car;
  List<ServiceRecord> _records = [];
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _args = args is GarageCarPageArgs
        ? args
        : GarageCarPageArgs(carId: 0);
    _car = _args.car;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _garageApi.getCar(_args.carId),
        _garageApi.getServiceRecords(_args.carId),
      ]);
      if (!mounted) return;
      setState(() {
        _car = results[0] as UserCar;
        _records = (results[1] as List).cast<ServiceRecord>();
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

  void _edit() {
    Navigator.pushNamed(
      context,
      '/garage/car/form',
      arguments: GarageCarFormArgs(car: _car),
    ).then((_) => _load());
  }

  void _addRecord() {
    Navigator.pushNamed(
      context,
      '/garage/service-record/form',
      arguments: GarageServiceRecordFormArgs(userCarId: _args.carId),
    ).then((_) => _load());
  }

  void _openRecord(ServiceRecord record) {
    Navigator.pushNamed(
      context,
      '/garage/service-record',
      arguments: GarageServiceRecordPageArgs(
        recordId: record.id,
        record: record,
        carDisplayName: _car?.displayName,
      ),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: const Text(
          'Все записи сервисной книги будут удалены вместе с автомобилем.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteCar();
  }

  Future<void> _deleteCar() async {
    setState(() => _isDeleting = true);
    try {
      await _garageApi.deleteCar(_args.carId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(
        title: _car?.displayName ?? 'Автомобиль',
        actions: [
          if (!_isLoading && _car != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: _isDeleting ? null : _edit,
            ),
          if (!_isLoading && _car != null)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: _isDeleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: _car != null
          ? FloatingActionButton.extended(
              onPressed: _addRecord,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить запись'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _car == null) {
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

    final car = _car!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // Карточка авто
          _InfoCard(
            children: [
              _InfoRow(label: 'Марка / Модель', value: '${car.brand} ${car.model}'),
              if (car.year != null) _InfoRow(label: 'Год', value: '${car.year}'),
              if (car.modification != null) ...[
                _InfoRow(
                  label: 'Модификация',
                  value: car.modification!.name,
                ),
                if (car.modification!.generation != null)
                  _InfoRow(label: 'Поколение', value: car.modification!.generation!),
              ],
              if (car.vin != null && car.vin!.isNotEmpty)
                _InfoRow(label: 'VIN', value: car.vin!),
              if (car.plateNumber != null && car.plateNumber!.isNotEmpty)
                _InfoRow(label: 'Гос. номер', value: car.plateNumber!),
              if (car.mileage != null)
                _InfoRow(label: 'Пробег', value: '${car.mileage} км'),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Text(
                'Сервисная книга',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_records.length})',
                style: const TextStyle(color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Записей пока нет',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            )
          else
            ...(_records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecordCard(
                  record: record,
                  onTap: () => _openRecord(record),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final ServiceRecord record;
  final VoidCallback onTap;
  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.build_outlined, color: AppColors.primarySoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.serviceType,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        record.serviceDate,
                        style: const TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                      if (record.mileage != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: Colors.black26),
                        ),
                        Text(
                          '${record.mileage} км',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                      if (record.totalCost != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: Colors.black26),
                        ),
                        Text(
                          '${record.totalCost!.toStringAsFixed(0)} ${record.currency ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
