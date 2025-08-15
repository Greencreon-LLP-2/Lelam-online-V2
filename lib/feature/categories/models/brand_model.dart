class BrandModel {
  final String id;
  final String slug;
  final String categoryId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  BrandModel({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      categoryId: json['category_id'] ?? '',
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
      'category_id': categoryId,
      'name': name,
      'image': image,
      'status': status,
      'created_on': createdOn,
      'updated_on': updatedOn,
    };
  }
}
