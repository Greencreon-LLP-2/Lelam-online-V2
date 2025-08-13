class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String orderLevel;
  final String image;
  final String featured;
  final String visiterCount;
  final String status;
  final String createdOn;
  final String updatedOn;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.orderLevel,
    required this.image,
    required this.featured,
    required this.visiterCount,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      orderLevel: json['order_level'] ?? '',
      image: json['image'] ?? '',
      featured: json['featured'] ?? '',
      visiterCount: json['visiter_count'] ?? '',
      status: json['status'] ?? '',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'order_level': orderLevel,
      'image': image,
      'featured': featured,
      'visiter_count': visiterCount,
      'status': status,
      'created_on': createdOn,
      'updated_on': updatedOn,
    };
  }
}
