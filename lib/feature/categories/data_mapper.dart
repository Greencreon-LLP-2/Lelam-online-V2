import 'package:lelamonline_flutter/feature/categories/models/details_model.dart';

class DataMapper {
  final List<Attribute> attributes;
  final List<AttributeVariation> attributeVariations;

  DataMapper({required this.attributes, required this.attributeVariations});

  String getAttributeName(String id) {
    try {
      return attributes.firstWhere((attr) => attr.id == id).name;
    } catch (e) {
      return 'N/A';
    }
  }

  String getAttributeVariationName(String id) {
    if (id.isEmpty) return 'N/A';
    try {
      return attributeVariations.firstWhere((v) => v.id == id).name;
    } catch (e) {
      return 'N/A';
    }
  }

  String getYear(String yearId) {
    return getAttributeVariationName(yearId);
  }

  String getOwnerText(String ownerId) {
    final ownerName = getAttributeVariationName(ownerId);
    if (ownerName != 'N/A') return ownerName;

    // Fallback to ordinal numbers if we only have an ID
    final ownerNum = int.tryParse(ownerId) ?? 0;
    switch (ownerNum) {
      case 1: return '1st Owner';
      case 2: return '2nd Owner';
      case 3: return '3rd Owner';
      default: 
        return ownerNum > 0 ? '${ownerNum}th Owner' : 'Not specified';
    }
  }

  String getFuelType(String fuelId) {
    return getAttributeVariationName(fuelId);
  }

  String getTransmission(String transmissionId) {
    return getAttributeVariationName(transmissionId);
  }
}