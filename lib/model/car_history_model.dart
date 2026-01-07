class CarHistoryModel {
  final int markId;
  final String markName;
  final String markCyrillicName;
  final String markCountry;
  final String markLogo;
  final int markYearFrom;
  final int markYearTo;

  final int modelId;
  final String modelName;
  final String modelCyrillicName;
  final int modelYearFrom;
  final int modelYearTo;

  final int generationId;
  final String generationName;
  final int generationYearFrom;
  final int generationYearTo;

  final int configurationId;
  final String configurationName;
  final String configurationBodyType;
  final int configurationDoorsCount;

  final int modificationId;
  final String modificationName;

  CarHistoryModel({
    required this.markId,
    required this.markName,
    required this.markCyrillicName,
    required this.markCountry,
    required this.markLogo,
    required this.markYearFrom,
    required this.markYearTo,
    required this.modelId,
    required this.modelName,
    required this.modelCyrillicName,
    required this.modelYearFrom,
    required this.modelYearTo,
    required this.generationId,
    required this.generationName,
    required this.generationYearFrom,
    required this.generationYearTo,
    required this.configurationId,
    required this.configurationName,
    required this.configurationBodyType,
    required this.configurationDoorsCount,
    required this.modificationId,
    required this.modificationName,
  });

  factory CarHistoryModel.fromJson(Map<String, dynamic> json) {
    return CarHistoryModel(
      markId: json['mark_id'],
      markName: json['mark_name'],
      markCyrillicName: json['mark_cyrillic_name'],
      markCountry: json['mark_country'],
      markLogo: json['mark_logo'],
      markYearFrom: json['mark_year_from'],
      markYearTo: json['mark_year_to'],
      modelId: json['model_id'],
      modelName: json['model_name'],
      modelCyrillicName: json['model_cyrillic_name'],
      modelYearFrom: json['model_year_from'],
      modelYearTo: json['model_year_to'],
      generationId: json['generation_id'],
      generationName: json['generation_name'],
      generationYearFrom: json['generation_year_from'],
      generationYearTo: json['generation_year_to'],
      configurationId: json['configuration_id'],
      configurationName: json['configuration_name'],
      configurationBodyType: json['configuration_body_type'],
      configurationDoorsCount: json['configuration_doors_count'],
      modificationId: json['modification_id'],
      modificationName: json['modification_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mark_id': markId,
      'mark_name': markName,
      'mark_cyrillic_name': markCyrillicName,
      'mark_country': markCountry,
      'mark_logo': markLogo,
      'mark_year_from': markYearFrom,
      'mark_year_to': markYearTo,
      'model_id': modelId,
      'model_name': modelName,
      'model_cyrillic_name': modelCyrillicName,
      'model_year_from': modelYearFrom,
      'model_year_to': modelYearTo,
      'generation_id': generationId,
      'generation_name': generationName,
      'generation_year_from': generationYearFrom,
      'generation_year_to': generationYearTo,
      'configuration_id': configurationId,
      'configuration_name': configurationName,
      'configuration_body_type': configurationBodyType,
      'configuration_doors_count': configurationDoorsCount,
      'modification_id': modificationId,
      'modification_name': modificationName,
    };
  }

  factory CarHistoryModel.fromMap(Map<dynamic, dynamic> map) {
    return CarHistoryModel(
      markId: map['mark_id'],
      markName: map['mark_name'],
      markCyrillicName: map['mark_cyrillic_name'],
      markCountry: map['mark_country'],
      markLogo: map['mark_logo'],
      markYearFrom: map['mark_year_from'],
      markYearTo: map['mark_year_to'],
      modelId: map['model_id'],
      modelName: map['model_name'],
      modelCyrillicName: map['model_cyrillic_name'],
      modelYearFrom: map['model_year_from'],
      modelYearTo: map['model_year_to'],
      generationId: map['generation_id'],
      generationName: map['generation_name'],
      generationYearFrom: map['generation_year_from'],
      generationYearTo: map['generation_year_to'],
      configurationId: map['configuration_id'],
      configurationName: map['configuration_name'],
      configurationBodyType: map['configuration_body_type'],
      configurationDoorsCount: map['configuration_doors_count'],
      modificationId: map['modification_id'],
      modificationName: map['modification_name'],
    );
  }
}
