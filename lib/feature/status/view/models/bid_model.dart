class Bid {
  final String productId;
  final String title;
  final String image;
  final DateTime currentDate;
  final DateTime expiryDate;
  final String price;
  final double bidPrice;
  final int meetingAttempts;
  final String location;

  Bid({
    required this.productId,
    required this.title,
    required this.image,
    required this.currentDate,
    required this.expiryDate,
    required this.price,
    required this.bidPrice,
    required this.meetingAttempts,
    required this.location,
  });

  // Optional: Add a method to convert Bid to JSON for storage
  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'image': image,
        'currentDate': currentDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'price': price,
        'bidPrice': bidPrice,
        'meetingAttempts': meetingAttempts,
        'location': location,
      };

  // Optional: Add a factory to create Bid from JSON
  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        productId: json['productId'],
        title: json['title'],
        image: json['image'],
        currentDate: DateTime.parse(json['currentDate']),
        expiryDate: DateTime.parse(json['expiryDate']),
        price: json['price'],
        bidPrice: json['bidPrice'],
        meetingAttempts: json['meetingAttempts'],
        location: json['location'],
      );
}