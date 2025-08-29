// models.dart

// 1. Brand
class Brand {
  final String id;
  final String slug;
  final String categoryId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  Brand({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      slug: json['slug'],
      categoryId: json['category_id'],
      name: json['name'],
      image: json['image'],
      status: json['status'],
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
    );
  }
}

// 2. Brand Model
class BrandModel {
  final String id;
  final String brandId;
  final String slug;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  BrandModel({
    required this.id,
    required this.brandId,
    required this.slug,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'],
      brandId: json['brand_id'],
      slug: json['slug'],
      name: json['name'],
      image: json['image'],
      status: json['status'],
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
    );
  }
}

// 3. Model Variation
class ModelVariation {
  final String id;
  final String slug;
  final String brandId;
  final String brandsModelId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  ModelVariation({
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

  factory ModelVariation.fromJson(Map<String, dynamic> json) {
    return ModelVariation(
      id: json['id'],
      slug: json['slug'],
      brandId: json['brand_id'],
      brandsModelId: json['brands_model_id'],
      name: json['name'],
      image: json['image'],
      status: json['status'],
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
    );
  }
}

// 4. Filter Attribute
class FilterAttribute {
  final String id;
  final String slug;
  final String name;
  final String listOrder;
  final String categoryId;
  final String formValidation;
  final String ifDetailsIcons;
  final String detailsIcons;
  final String detailsIconsOrder;
  final String showFilter;
  final String status;
  final String createdOn;
  final String updatedOn;

  FilterAttribute({
    required this.id,
    required this.slug,
    required this.name,
    required this.listOrder,
    required this.categoryId,
    required this.formValidation,
    required this.ifDetailsIcons,
    required this.detailsIcons,
    required this.detailsIconsOrder,
    required this.showFilter,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory FilterAttribute.fromJson(Map<String, dynamic> json) {
    return FilterAttribute(
      id: json['id'],
      slug: json['slug'],
      name: json['name'],
      listOrder: json['list_order'],
      categoryId: json['category_id'],
      formValidation: json['form_validation'],
      ifDetailsIcons: json['if_details_icons'],
      detailsIcons: json['details_icons'],
      detailsIconsOrder: json['details_icons_order'],
      showFilter: json['show_filter'],
      status: json['status'],
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
    );
  }
}

// 5. Filter Attribute Variation
class FilterAttributeVariation {
  final String id;
  final String attributeId;
  final String name;
  final String status;
  final String createdOn;
  final String updatedOn;

  FilterAttributeVariation({
    required this.id,
    required this.attributeId,
    required this.name,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory FilterAttributeVariation.fromJson(Map<String, dynamic> json) {
    return FilterAttributeVariation(
      id: json['id'],
      attributeId: json['attribute_id'],
      name: json['name'],
      status: json['status'],
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
    );
  }
}
