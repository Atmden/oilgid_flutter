import 'attachment.dart';
import 'expense_category.dart';
import 'service_item.dart';

class ServiceRecord {
  final int id;
  final int userCarId;
  final String serviceDate;
  final int? mileage;
  final int? categoryId;
  final ExpenseCategory? category;
  final String? notes;
  final double? totalCost;
  final String? currency;
  final List<ServiceItem> items;
  final List<Attachment> attachments;

  const ServiceRecord({
    required this.id,
    required this.userCarId,
    required this.serviceDate,
    this.mileage,
    this.categoryId,
    this.category,
    this.notes,
    this.totalCost,
    this.currency,
    required this.items,
    required this.attachments,
  });

  String get displayName => category?.name ?? notes ?? 'Запись';
}
