class AttributeValuePair {
  final String attributeName;
  final String attributeValue;

  AttributeValuePair({
    required this.attributeName,
    required this.attributeValue,
  });

  factory AttributeValuePair.fromJson(Map<String, dynamic> json) {
    return AttributeValuePair(
      attributeName: json['attribute_name']?.toString() ?? '',
      attributeValue: json['attribute_value']?.toString() ?? '',
    );
  }
}