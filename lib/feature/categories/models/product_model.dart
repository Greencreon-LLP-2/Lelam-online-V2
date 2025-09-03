class Product {
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
  final Map<String, String> filters;
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

  Product({
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
}