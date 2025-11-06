import 'dart:convert';

class FeatureListModel {
  final String id;
  final String slug;
  final String title;
  final String categoryId;
  final String image;
  final String brand;
  final String model;
  final String modelVariation;
  final String description;
  final String price;
  final String auctionPriceIntervel;
  final String auctionStartingPrice;
  final List<String> attributeId;
  final List<String> attributeVariationsId;
  final Map<String, dynamic> filters;
  final String latitude;
  final String longitude;
  final String userZoneId;
  final String parentZoneId;
  final String zoneId;
  final String landMark;
  final String ifAuction;
  final String auctionStatus;
  final String auctionStartin;
  final String auctionEndin;
  final String auctionAttempt;
  final String adminApproval;
  final String ifFinance;
  final String ifExchange;
  final String feature;
  final String status;
  final String visiterCount;
  final String ifSold;
  final String ifExpired;
  final String byDealer;
  final String createdBy;
  final String createdOn;
  final String updatedOn;

  FeatureListModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.categoryId,
    required this.image,
    required this.brand,
    required this.model,
    required this.modelVariation,
    required this.description,
    required this.price,
    required this.auctionPriceIntervel,
    required this.auctionStartingPrice,
    required this.attributeId,
    required this.attributeVariationsId,
    required this.filters,
    required this.latitude,
    required this.longitude,
    required this.userZoneId,
    required this.parentZoneId,
    required this.zoneId,
    required this.landMark,
    required this.ifAuction,
    required this.auctionStatus,
    required this.auctionStartin,
    required this.auctionEndin,
    required this.auctionAttempt,
    required this.adminApproval,
    required this.ifFinance,
    required this.ifExchange,
    required this.feature,
    required this.status,
    required this.visiterCount,
    required this.ifSold,
    required this.ifExpired,
    required this.byDealer,
    required this.createdBy,
    required this.createdOn,
    required this.updatedOn,
  });

  factory FeatureListModel.fromJson(Map<String, dynamic> json) {
    return FeatureListModel(
      id: _toString(json['id']),
      slug: _toString(json['slug']),
      title: _toString(json['title']),
      categoryId: _toString(json['category_id']),
      image: _toString(json['image']),
      brand: _toString(json['brand']),
      model: _toString(json['model']),
      modelVariation: _toString(json['model_variation']),
      description: _toString(json['description']),
      price: _toString(json['price']),
      auctionPriceIntervel: _toString(json['auction_price_intervel']),
      auctionStartingPrice: _toString(json['auction_starting_price']),
      attributeId: _parseStringList(json['attribute_id']),
      attributeVariationsId: _parseStringList(json['attribute_variations_id']),
      filters: _parseFilters(json['filters']),
      latitude: _toString(json['latitude']),
      longitude: _toString(json['longitude']),
      userZoneId: _toString(json['user_zone_id']),
      parentZoneId: _toString(json['parent_zone_id']),
      zoneId: _toString(json['zone_id']),
      landMark: _toString(json['land_mark']),
      ifAuction: _toString(json['if_auction']),
      auctionStatus: _toString(json['auction_status']),
      auctionStartin: _toString(json['auction_startin']),
      auctionEndin: _toString(json['auction_endin']),
      auctionAttempt: _toString(json['auction_attempt']),
      adminApproval: _toString(json['admin_approval']),
      ifFinance: _toString(json['if_finance']),
      ifExchange: _toString(json['if_exchange']),
      feature: _toString(json['feature']),
      status: _toString(json['status']),
      visiterCount: _toString(json['visiter_count']),
      ifSold: _toString(json['if_sold']),
      ifExpired: _toString(json['if_expired']),
      byDealer: _toString(json['by_dealer']),
      createdBy: _toString(json['created_by']),
      createdOn: _toString(json['created_on']),
      updatedOn: _toString(json['updated_on']),
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];

    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        return [value];
      } catch (_) {
        return [value];
      }
    } else if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }

  static Map<String, dynamic> _parseFilters(dynamic value) {
    if (value == null) return {};

    if (value is String) {
      if (value.isEmpty) return {};
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return {};
      } catch (_) {
        return {};
      }
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }
}
