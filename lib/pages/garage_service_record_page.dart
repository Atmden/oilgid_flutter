import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_gallery.dart';
import 'package:oil_gid/features/garage/domain/entities/service_record.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageServiceRecordPage extends StatefulWidget {
  const GarageServiceRecordPage({super.key});

  @override
  State<GarageServiceRecordPage> createState() =>
      _GarageServiceRecordPageState();
}

class _GarageServiceRecordPageState extends State<GarageServiceRecordPage> {
  final _garageApi = AppApi().garageApi;

  late GarageServiceRecordPageArgs _args;
  bool _initialized = false;

  ServiceRecord? _record;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _args = args is GarageServiceRecordPageArgs
        ? args
        : GarageServiceRecordPageArgs(recordId: 0);
    _record = _args.record;
    if (_record != null) {
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final record = await _garageApi.getServiceRecord(_args.recordId);
      if (!mounted) return;
      setState(() => _record = record);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _edit() {
    final record = _record!;
    Navigator.pushNamed(
      context,
      '/garage/service-record/form',
      arguments: GarageServiceRecordFormArgs(
        userCarId: record.userCarId,
        record: record,
      ),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Запись и все вложения будут удалены.'),
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

    setState(() => _isDeleting = true);
    try {
      await _garageApi.deleteServiceRecord(_args.recordId);
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
        title: _record?.displayName ?? 'Запись',
        actions: [
          if (!_isLoading && _record != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: _isDeleting ? null : _edit,
            ),
          if (!_isLoading && _record != null)
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _record == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    final record = _record!;
    final cat = record.category;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Категория + основная инфо
          _Section(
            children: [
              if (cat != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
              _Row(label: 'Дата', value: record.serviceDate),
              if (record.mileage != null)
                _Row(label: 'Пробег', value: '${record.mileage} км'),
              if (record.totalCost != null)
                _Row(
                  label: 'Стоимость',
                  value:
                      '${record.totalCost!.toStringAsFixed(2)} ${record.currency ?? ''}',
                ),
              if (record.notes != null && record.notes!.trim().isNotEmpty)
                _Row(label: 'Заметки', value: record.notes!),
            ],
          ),

          // Позиции
          if (record.items.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Позиции',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _Section(
              children: record.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(item.name)),
                          Text(
                            '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Вложения
          if (record.attachments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Фото',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OilGallery(
              images: record.attachments.map((a) => a.url).toList(),
              onTap: (index) => _openImageFullscreen(
                record.attachments.map((a) => a.url).toList(),
                index,
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openImageFullscreen(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) =>
          _FullscreenGallery(images: images, initialIndex: initialIndex),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGallery(
      {required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == i ? 10 : 6,
                    height: _currentIndex == i ? 10 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white
                          : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
