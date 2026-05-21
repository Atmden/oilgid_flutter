import '../../../../core/utils/parsers.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/entities/service_record.dart';
import 'expense_category_model.dart';

class ServiceItemModel extends ServiceItem {
  const ServiceItemModel({
    super.id,
    required super.name,
    required super.quantity,
    required super.unitPrice,
  });

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    return ServiceItemModel(
      id: toIntSafe(json['id']),
      name: json['name']?.toString() ?? '',
      quantity: toIntSafe(json['quantity']) ?? 1,
      unitPrice: toDoubleSafe(json['unit_price']) ?? 0.0,
    );
  }
}

class AttachmentModel extends Attachment {
  const AttachmentModel({
    required super.id,
    required super.url,
    required super.name,
    required super.mimeType,
    required super.size,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: toIntSafe(json['id']) ?? 0,
      url: json['url']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: toIntSafe(json['size']) ?? 0,
    );
  }
}

class ServiceRecordModel extends ServiceRecord {
  const ServiceRecordModel({
    required super.id,
    required super.userCarId,
    required super.serviceDate,
    super.mileage,
    super.categoryId,
    super.category,
    super.notes,
    super.totalCost,
    super.currency,
    required super.items,
    required super.attachments,
  });

  factory ServiceRecordModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final attachmentsRaw = json['attachments'] as List<dynamic>? ?? [];

    ExpenseCategory? category;
    final categoryRaw = json['category'];
    if (categoryRaw is Map<String, dynamic>) {
      category = ExpenseCategoryModel.fromJson(categoryRaw);
    }

    return ServiceRecordModel(
      id: toIntSafe(json['id']) ?? 0,
      userCarId: toIntSafe(json['user_car_id']) ?? 0,
      serviceDate: json['service_date']?.toString() ?? '',
      mileage: toIntSafe(json['mileage']),
      categoryId: toIntSafe(json['category_id']),
      category: category,
      notes: json['notes']?.toString(),
      totalCost: toDoubleSafe(json['total_cost']),
      currency: json['currency']?.toString(),
      items: itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(ServiceItemModel.fromJson)
          .toList(),
      attachments: attachmentsRaw
          .whereType<Map<String, dynamic>>()
          .map(AttachmentModel.fromJson)
          .toList(),
    );
  }
}
