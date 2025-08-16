import 'dart:convert';
import 'package:http/http.dart' as http;

// Model class for Marketplace Post
class MarketplacePost {
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
  final String auctionPriceInterval;
  final String auctionStartingPrice;
  final List<String> attributeId;
  final List<String> attributeVariationsId;
  final Map<String, List<String>> filters;
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

  MarketplacePost({
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
    required this.auctionPriceInterval,
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

  factory MarketplacePost.fromJson(Map<String, dynamic> json) {
    return MarketplacePost(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      categoryId: json['category_id'] ?? '',
      image: json['image'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      modelVariation: json['model_variation'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '',
      auctionPriceInterval: json['auction_price_intervel'] ?? '',
      auctionStartingPrice: json['auction_starting_price'] ?? '',
      attributeId: json['attribute_id'] != null
          ? List<String>.from(jsonDecode(json['attribute_id']))
          : [],
      attributeVariationsId: json['attribute_variations_id'] != null
          ? List<String>.from(jsonDecode(json['attribute_variations_id']))
          : [],
      filters: json['filters'] != null
          ? Map<String, List<String>>.from(
              jsonDecode(json['filters']).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            )
          : {},
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      userZoneId: json['user_zone_id'] ?? '',
      parentZoneId: json['parent_zone_id'] ?? '',
      zoneId: json['zone_id'] ?? '',
      landMark: json['land_mark'] ?? '',
      ifAuction: json['if_auction'] ?? '',
      auctionStatus: json['auction_status'] ?? '',
      auctionStartin: json['auction_startin'] ?? '',
      auctionEndin: json['auction_endin'] ?? '',
      auctionAttempt: json['auction_attempt'] ?? '',
      adminApproval: json['admin_approval'] ?? '',
      ifFinance: json['if_finance'] ?? '',
      ifExchange: json['if_exchange'] ?? '',
      feature: json['feature'] ?? '',
      status: json['status'] ?? '',
      visiterCount: json['visiter_count'] ?? '',
      ifSold: json['if_sold'] ?? '',
      ifExpired: json['if_expired'] ?? '',
      byDealer: json['by_dealer'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
    );
  }
}