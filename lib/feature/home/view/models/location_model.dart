import 'dart:convert';

class LocationResponse {
  final bool status;
  final List<LocationData> data;

  LocationResponse({
    required this.status,
    required this.data,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      status: json['status'].toString() == "true",
      data: (json['data'] as List)
          .map((item) => LocationData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status.toString(),
      "data": data.map((e) => e.toJson()).toList(),
    };
  }
}

class LocationData {
  final String id;
  final String slug;
  final String parentId;
  final String name;
  final String image;
  final String description;
  final String latitude;
  final String longitude;
  final String popular;
  final String status;
  final String allStoreOnOff;
  final String createdOn;
  final String updatedOn;

  LocationData({
    required this.id,
    required this.slug,
    required this.parentId,
    required this.name,
    required this.image,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.popular,
    required this.status,
    required this.allStoreOnOff,
    required this.createdOn,
    required this.updatedOn,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      popular: json['popular'] ?? '',
      status: json['status'] ?? '',
      allStoreOnOff: json['allstore_onoff'] ?? '',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "slug": slug,
      "parent_id": parentId,
      "name": name,
      "image": image,
      "description": description,
      "latitude": latitude,
      "longitude": longitude,
      "popular": popular,
      "status": status,
      "allstore_onoff": allStoreOnOff,
      "created_on": createdOn,
      "updated_on": updatedOn,
    };
  }
}

