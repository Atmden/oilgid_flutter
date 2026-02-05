import 'oil_brand.dart';
import 'oil_specification.dart';

class OilItem {
  final int id;
  final String title;
  final String slug;
  final OilBrand? brand;
  final int brandId;
  final String brandTitle;
  final int viscosityId;
  final String viscosityTitle;
  final int specificationId;
  final String specificationTitle;
  final OilSpecification? specification;
  final String description;
  final String thumb;
  final List<String> images;

  OilItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.brand,
    required this.brandId,
    required this.brandTitle,
    required this.viscosityId,
    required this.viscosityTitle,
    required this.specificationId,
    required this.specificationTitle,
    required this.specification,
    required this.description,
    required this.thumb,
    required this.images,
  });
}
