import 'dart:convert';

import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';

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
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List)
            return List<String>.from(decoded.map((e) => e.toString()));
        } catch (e) {
          return value.split(',').map((e) => e.trim()).toList();
        }
      }
      return [];
    }

    Map<String, List<String>> parseFilters(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, List<String>>.from(
          value.map((key, value) {
            return MapEntry(key.toString(), parseStringList(value));
          }),
        );
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            return Map<String, List<String>>.from(
              decoded.map((key, value) {
                return MapEntry(key.toString(), parseStringList(value));
              }),
            );
          }
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    return MarketplacePost(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      modelVariation: json['model_variation']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      auctionPriceInterval: json['auction_price_intervel']?.toString() ?? '0',
      auctionStartingPrice: json['auction_starting_price']?.toString() ?? '0',
      attributeId: parseStringList(json['attribute_id']),
      attributeVariationsId: parseStringList(json['attribute_variations_id']),
      filters: parseFilters(json['filters']),
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      userZoneId: json['user_zone_id']?.toString() ?? '',
      parentZoneId: json['parent_zone_id']?.toString() ?? '',
      landMark: json['land_mark']?.toString() ?? '',
      ifAuction: json['if_auction']?.toString() ?? '0',
      auctionStatus: json['auction_status']?.toString() ?? '',
      auctionStartin: json['auction_startin']?.toString() ?? '',
      auctionEndin: json['auction_endin']?.toString() ?? '',
      auctionAttempt: json['auction_attempt']?.toString() ?? '0',
      adminApproval: json['admin_approval']?.toString() ?? '0',
      ifFinance: json['if_finance']?.toString() ?? '0',
      ifExchange: json['if_exchange']?.toString() ?? '0',
      feature: json['feature']?.toString() ?? '0',
      status: json['status']?.toString() ?? '0',
      visiterCount: json['visiter_count']?.toString() ?? '0',
      ifSold: json['if_sold']?.toString() ?? '0',
      ifExpired: json['if_expired']?.toString() ?? '0',
      byDealer: json['by_dealer']?.toString() ?? '0',
      createdBy: json['created_by']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }

  Product toProduct() {
    final convertedFilters = filters.map(
      (key, value) => MapEntry(key, value.isNotEmpty ? value.first : ''),
    );

    return Product(
      id: id,
      slug: slug,
      title: title,
      categoryId: categoryId,
      image: image,
      brand: brand,
      model: model,
      modelVariation: modelVariation,
      description: description,
      price: price,
      auctionPriceIntervel: auctionPriceInterval,
      auctionStartingPrice: auctionStartingPrice,
      attributeId: attributeId,
      attributeVariationsId: attributeVariationsId,
      filters: convertedFilters,
      latitude: latitude,
      longitude: longitude,
      userZoneId: userZoneId,
      parentZoneId: parentZoneId,
      landMark: landMark,
      ifAuction: ifAuction,
      auctionStatus: auctionStatus,
      auctionStartin: auctionStartin,
      auctionEndin: auctionEndin,
      auctionAttempt: auctionAttempt,
      adminApproval: adminApproval,
      ifFinance: ifFinance,
      ifExchange: ifExchange,
      feature: feature,
      status: status,
      visiterCount: visiterCount,
      ifSold: ifSold,
      ifExpired: ifExpired,
      byDealer: byDealer,
      createdBy: createdBy,
      createdOn: createdOn,
      updatedOn: updatedOn,
    );
  }
}