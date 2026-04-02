import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class AddCarRequestPage extends StatefulWidget {
  const AddCarRequestPage({super.key});

  @override
  State<AddCarRequestPage> createState() => _AddCarRequestPageState();
}

class _AddCarRequestPageState extends State<AddCarRequestPage> {
  bool isLoading = false;
  final AppApi _appApi = AppApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _markController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _engineController;
  String? _transmissionType;
  String? _engineType;
  String? _bodyType;
  String? _driveType;
  late final TextEditingController _descriptionTextController;

  @override
  void initState() {
    super.initState();
    _markController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _engineController = TextEditingController();
    _descriptionTextController = TextEditingController();
  }

  @override
  void dispose() {
    _markController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _descriptionTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Оставить заявку'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оставить заявку',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Пожалуйста, заполните форму ниже, чтобы оставить заявку на добавление вашего автомобиля.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _markController,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Марка автомобиля',
                      suffixIcon: Icon(Icons.car_repair),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Укажите марку автомобиля';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Модель автомобиля (код, поколение)',
                      suffixIcon: Icon(Icons.car_repair),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Укажите модель автомобиля';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Год выпуска',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Укажите год выпуска';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _engineController,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Двигатель (код двигателя, объем двигателя)',
                      suffixIcon: Icon(Icons.car_repair),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Укажите двигатель';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _transmissionType,
                    onChanged: isLoading
                        ? null
                        : (value) => setState(
                            () => _transmissionType = value as String?,
                          ),
                    validator: (v) => v == null ? 'Выберите КПП' : null,
                    decoration: InputDecoration(labelText: 'Коробка передач'),
                    items: [
                      DropdownMenuItem(
                        value: 'механическая',
                        child: Text('Механическая'),
                      ),
                      DropdownMenuItem(
                        value: 'автоматическая',
                        child: Text('Автоматическая'),
                      ),
                      DropdownMenuItem(
                        value: 'роботизированная',
                        child: Text('Роботизированная'),
                      ),
                      DropdownMenuItem(
                        value: 'вариатор',
                        child: Text('Вариатор'),
                      ),
                      DropdownMenuItem(value: 'другой', child: Text('Другой')),
                    ],
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _engineType,
                    validator: (v) =>
                        v == null ? 'Выберите тип двигателя' : null,
                    decoration: InputDecoration(labelText: 'Тип двигателя'),
                    items: [
                      DropdownMenuItem(value: 'бензин', child: Text('Бензин')),
                      DropdownMenuItem(value: 'дизель', child: Text('Дизель')),
                      DropdownMenuItem(
                        value: 'электрический',
                        child: Text('Электрический'),
                      ),
                      DropdownMenuItem(
                        value: 'гибридный',
                        child: Text('Гибридный'),
                      ),
                      DropdownMenuItem(
                        value: 'газодиэлектрический',
                        child: Text('Газодиэлектрический'),
                      ),
                      DropdownMenuItem(
                        value: 'газодизельный',
                        child: Text('Газодизельный'),
                      ),
                      DropdownMenuItem(value: 'другой', child: Text('Другой')),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) =>
                              setState(() => _engineType = value as String?),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _bodyType,
                    validator: (v) => v == null ? 'Выберите тип кузова' : null,
                    decoration: InputDecoration(labelText: 'Тип кузова'),
                    items: [
                      DropdownMenuItem(value: 'седан', child: Text('Седан')),
                      DropdownMenuItem(
                        value: 'хэтчбек',
                        child: Text('Хэтчбек'),
                      ),
                      DropdownMenuItem(
                        value: 'универсал',
                        child: Text('Универсал'),
                      ),
                      DropdownMenuItem(value: 'купе', child: Text('Купе')),
                      DropdownMenuItem(
                        value: 'родстер',
                        child: Text('Родстер'),
                      ),
                      DropdownMenuItem(
                        value: 'кабриолет',
                        child: Text('Кабриолет'),
                      ),
                      DropdownMenuItem(value: 'фургон', child: Text('Фургон')),
                      DropdownMenuItem(value: 'другой', child: Text('Другой')),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) =>
                              setState(() => _bodyType = value as String?),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _driveType,
                    validator: (v) => v == null ? 'Выберите тип привода' : null,
                    decoration: InputDecoration(labelText: 'Тип привода'),
                    items: [
                      DropdownMenuItem(
                        value: 'передний',
                        child: Text('Передний'),
                      ),
                      DropdownMenuItem(value: 'задний', child: Text('Задний')),
                      DropdownMenuItem(value: 'полный', child: Text('Полный')),
                      DropdownMenuItem(value: 'другой', child: Text('Другой')),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) =>
                              setState(() => _driveType = value as String?),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionTextController,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Дополнительная информация (необязательно)',
                      suffixIcon: Icon(Icons.description),
                    ),
                  ),

                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false))
                              return;
                            final data = <String, dynamic>{
                              'mark': _markController.text.trim(),
                              'model': _modelController.text.trim(),
                              'year': _yearController.text.trim(),
                              'engine': _engineController.text.trim(),
                              'transmission': _transmissionType,
                              'engine_type': _engineType,
                              'body_type': _bodyType,
                              'drive_type': _driveType,
                              'description': _descriptionTextController.text
                                  .trim(),
                            };
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              final response = await _appApi.addCarRequest(
                                data,
                              );
                              if (response['success'] == true) {
                                if (!mounted) return;
                                _formKey.currentState?.reset();
                                setState(() {
                                  _transmissionType = null;
                                  _engineType = null;
                                  _bodyType = null;
                                  _driveType = null;
                                });

                               
                                Navigator.of(context).pop(true);
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response['message'] ??
                                          'Не удалось отправить заявку',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Не удалось отправить заявку'),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                    icon: isLoading ? const CircularProgressIndicator() : null,
                    label: Text(
                      'Отправить заявку',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
