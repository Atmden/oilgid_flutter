import '../../domain/entities/oil_item.dart';
import '../../domain/entities/oil_specification.dart';
import '../../domain/entities/oil_approval.dart';
import 'oil_brand_model.dart';

class OilApprovalModel extends OilApproval {
  OilApprovalModel({required super.id, required super.title});

  factory OilApprovalModel.fromJson(Map<String, dynamic> json) {
    return OilApprovalModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class OilSpecificationModel extends OilSpecification {
  OilSpecificationModel({
    required super.id,
    required super.title,
    required super.viscosityId,
    required super.viscosityTitle,
    required super.aceas,
    required super.apis,
    required super.oemApprovals,
    required super.ilsacs,
  });

  factory OilSpecificationModel.fromJson(Map<String, dynamic> json) {
    List<OilApprovalModel> parseList(dynamic list) {
      return (list as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OilApprovalModel.fromJson)
          .toList();
    }

    return OilSpecificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      viscosityId: json['viscosity_id'] ?? 0,
      viscosityTitle: json['viscosity_title'] ?? '',
      aceas: parseList(json['aceas']),
      apis: parseList(json['apis']),
      oemApprovals: parseList(json['oem_approvals']),
      ilsacs: parseList(json['ilsacs']),
    );
  }
}

class OilItemModel extends OilItem {
  OilItemModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.brand,
    required super.brandId,
    required super.brandTitle,
    required super.viscosityId,
    required super.viscosityTitle,
    required super.specificationId,
    required super.specificationTitle,
    required super.specification,
    required super.description,
    required super.thumb,
    required super.images,
  });

  factory OilItemModel.fromJson(Map<String, dynamic> json) {
    final brandJson = json['brand'];
    final specJson = json['specification'];
    return OilItemModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      brand: brandJson is Map<String, dynamic>
          ? OilBrandModel.fromJson(brandJson)
          : null,
      brandId: json['brand_id'] ?? 0,
      brandTitle: json['brand_title'] ?? '',
      viscosityId: json['viscosity_id'] ?? 0,
      viscosityTitle: json['viscosity_title'] ?? '',
      specificationId: json['specification_id'] ?? 0,
      specificationTitle: json['specification_title'] ?? '',
      specification: specJson is Map<String, dynamic>
          ? OilSpecificationModel.fromJson(specJson)
          : null,
      description: json['description'] ?? '',
      thumb: json['thumb'] ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
