class BrandVariantModel {
  final String id;
  final String slug;
  final String brandId;
  final String brandsModelId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  BrandVariantModel({
    required this.id,
    required this.slug,
    required this.brandId,
    required this.brandsModelId,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory BrandVariantModel.fromJson(Map<String, dynamic> json) {
    return BrandVariantModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      brandId: json['brand_id'] ?? '',
      brandsModelId: json['brands_model_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      status: json['status'] ?? '',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'brand_id': brandId,
      'brands_model_id': brandsModelId,
      'name': name,
      'image': image,
      'status': status,
      'created_on': createdOn,
      'updated_on': updatedOn,
    };
  }
}
