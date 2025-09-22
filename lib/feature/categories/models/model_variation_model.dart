class ModelVariation {
  final String brand;
  final String model;
  final String variations;

  ModelVariation({
    required this.brand,
    required this.model,
    required this.variations,
  });

  factory ModelVariation.fromJson(Map<String, dynamic> json) {
    return ModelVariation(
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      variations: json['variations'] ?? '',
    );
  }
}