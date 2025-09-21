class SellerCommentsModel {
  final String status;
  late final List<SellerComment> data;
  final String code;

  SellerCommentsModel({
    required this.status,
    required this.data,
    required this.code,
  });

  factory SellerCommentsModel.fromJson(Map<String, dynamic> json) {
    return SellerCommentsModel(
      status: json['status'] ?? 'false',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => SellerComment.fromJson(item))
              .toList() ??
          [],
      code: json['code'] ?? '',
    );
  }
}

class SellerComment {
  final String attributeName;
  final String attributeValue;

  SellerComment({required this.attributeName, required this.attributeValue});

  factory SellerComment.fromJson(Map<String, dynamic> json) {
    return SellerComment(
      attributeName: json['attribute_name'] ?? '',
      attributeValue: json['attribute_value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'attribute_name': attributeName, 'attribute_value': attributeValue};
  }
}
