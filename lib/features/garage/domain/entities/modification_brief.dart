class ModificationBrief {
  final int id;
  final String name;
  final String mark;
  final String model;
  final String? generation;

  const ModificationBrief({
    required this.id,
    required this.name,
    required this.mark,
    required this.model,
    this.generation,
  });
}
