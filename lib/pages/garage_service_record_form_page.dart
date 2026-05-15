import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/garage/domain/entities/attachment.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageServiceRecordFormPage extends StatefulWidget {
  const GarageServiceRecordFormPage({super.key});

  @override
  State<GarageServiceRecordFormPage> createState() =>
      _GarageServiceRecordFormPageState();
}

class _GarageServiceRecordFormPageState
    extends State<GarageServiceRecordFormPage> {
  final _garageApi = AppApi().garageApi;
  final _picker = ImagePicker();

  late GarageServiceRecordFormArgs _args;
  bool _initialized = false;

  final _serviceTypeController = TextEditingController();
  final _mileageController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCurrency = 'KZT';
  DateTime _selectedDate = DateTime.now();

  final List<_ItemRow> _items = [];
  final List<Attachment> _existingAttachments = [];
  final List<XFile> _newFiles = [];
  final List<int> _deletingMediaIds = [];

  bool _isSaving = false;
  String? _error;

  static const _currencies = ['RUB', 'USD', 'KZT', 'EUR'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _args = args is GarageServiceRecordFormArgs
        ? args
        : GarageServiceRecordFormArgs(userCarId: 0);

    final record = _args.record;
    if (record != null) {
      _serviceTypeController.text = record.serviceType;
      _mileageController.text = record.mileage?.toString() ?? '';
      _totalCostController.text = record.totalCost != null
          ? record.totalCost!.toStringAsFixed(2)
          : '';
      _notesController.text = record.notes ?? '';
      _selectedCurrency = record.currency ?? 'KZT';
      final parsed = DateTime.tryParse(record.serviceDate);
      if (parsed != null) _selectedDate = parsed;
      _existingAttachments.addAll(record.attachments);
      _items.addAll(record.items.map(
        (i) => _ItemRow(
          nameController: TextEditingController(text: i.name),
          quantityController:
              TextEditingController(text: i.quantity.toString()),
          priceController:
              TextEditingController(text: i.unitPrice.toStringAsFixed(2)),
        ),
      ));
    }
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _mileageController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _picker.pickMultiImage();
                if (files.isNotEmpty) {
                  setState(() => _newFiles.addAll(files));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null) {
                  setState(() => _newFiles.add(file));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final item = _ItemRow();
    item.quantityController.addListener(_onItemChanged);
    item.priceController.addListener(_onItemChanged);
    setState(() => _items.add(item));
  }

  void _onItemChanged() => setState(() {});

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double _computeTotal() {
    double total = 0;
    for (final item in _items) {
      final qty = double.tryParse(item.quantityController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _deleteExistingAttachment(Attachment attachment) async {
    if (!_args.isEdit) return;
    final recordId = _args.record!.id;
    setState(() => _deletingMediaIds.add(attachment.id));
    try {
      await _garageApi.deleteMedia(recordId, attachment.id);
      if (!mounted) return;
      setState(() => _existingAttachments.remove(attachment));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _deletingMediaIds.remove(attachment.id));
    }
  }

  Future<void> _save() async {
    final serviceType = _serviceTypeController.text.trim();
    if (serviceType.isEmpty) {
      setState(() => _error = 'Введите тип обслуживания.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final itemsPayload = _items
          .where((i) => i.nameController.text.trim().isNotEmpty)
          .map((i) => {
                'name': i.nameController.text.trim(),
                'quantity': int.tryParse(i.quantityController.text) ?? 1,
                'unit_price': double.tryParse(i.priceController.text) ?? 0.0,
              })
          .toList();

      final data = <String, dynamic>{
        'user_car_id': _args.userCarId,
        'service_date': dateStr,
        'service_type': serviceType,
        if (_mileageController.text.trim().isNotEmpty)
          'mileage': int.tryParse(_mileageController.text.trim()),
        'total_cost': _items.isNotEmpty
            ? _computeTotal()
            : double.tryParse(_totalCostController.text.trim()),
        'currency': _selectedCurrency,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        if (itemsPayload.isNotEmpty) 'items': itemsPayload,
      };

      final record = _args.isEdit
          ? await _garageApi.updateServiceRecord(_args.record!.id, data)
          : await _garageApi.createServiceRecord(data);

      // Загрузить новые файлы — ошибки загрузки не блокируют сохранение записи
      String? uploadError;
      for (final file in _newFiles) {
        try {
          await _garageApi.uploadMedia(record.id, file.path, file.name);
        } catch (e) {
          uploadError = 'Запись сохранена, но не все фото загружены.';
        }
      }

      if (!mounted) return;
      if (uploadError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadError), backgroundColor: Colors.orange),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: Colors.white,
        title: Text(_args.isEdit ? 'Редактировать запись' : 'Новая запись'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Дата
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.black45,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      const Text(
                        'Дата обслуживания',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _serviceTypeController,
                decoration: const InputDecoration(
                  labelText: 'Тип обслуживания *',
                  hintText: 'Например: Замена масла и фильтров',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Пробег (км)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  if (_items.isEmpty)
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _totalCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Итоговая стоимость',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  if (_items.isEmpty) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Валюта',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _currencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCurrency = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // Позиции
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Позиции',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primarySoft,
                    ),
                  ),
                ],
              ),

              if (_items.isNotEmpty) ...[
                const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Наименование',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        'Кол.',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Цена',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 4),
                ...List.generate(
                  _items.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _items[i].nameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Название',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: TextField(
                            controller: _items[i].quantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: '1',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _items[i].priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _removeItem(i),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${_computeTotal().toStringAsFixed(2)} $_selectedCurrency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Вложения
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Фото',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Добавить'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primarySoft,
                    ),
                  ),
                ],
              ),

              if (_existingAttachments.isNotEmpty || _newFiles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._existingAttachments.map(
                      (a) => _AttachmentThumb(
                        isDeleting: _deletingMediaIds.contains(a.id),
                        onDelete: () => _deleteExistingAttachment(a),
                        child: a.isImage
                            ? Image.network(
                                a.url,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.picture_as_pdf, size: 40),
                      ),
                    ),
                    ..._newFiles.map(
                      (f) => _AttachmentThumb(
                        onDelete: () =>
                            setState(() => _newFiles.remove(f)),
                        child: Image.file(
                          File(f.path),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_args.isEdit ? 'Сохранить' : 'Создать'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;

  _ItemRow({
    TextEditingController? nameController,
    TextEditingController? quantityController,
    TextEditingController? priceController,
  })  : nameController = nameController ?? TextEditingController(),
        quantityController =
            quantityController ?? TextEditingController(text: '1'),
        priceController = priceController ?? TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class _AttachmentThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _AttachmentThumb({
    required this.child,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.black12,
              alignment: Alignment.center,
              child: child,
            ),
          ),
          if (isDeleting)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white54,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
