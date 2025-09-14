class UserData {
  final String userId;
  final String userLevel;
  final String username;
  final String password;
  final String email;
  final String mobileCode;
  final String mobile;
  final String name;
  final String? profile;
  final String subscriptionId;
  final String latitude;
  final String longitude;
  final String locationName;
  final String zone;
  final String zoneName;
  final String code;
  final String status;
  final String mobileVerify;
  final String ban;
  final String createdOn;
  final String updatedOn;

  // --- Profile fields ---
  final String profileId;
  final String address1;
  final String address2;
  final String state;
  final String pincode;
  final String city;
  final String country;
  final String? image;

  UserData({
    required this.userId,
    required this.userLevel,
    required this.username,
    required this.password,
    required this.email,
    required this.mobileCode,
    required this.mobile,
    required this.name,
    this.profile,
    required this.subscriptionId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.zone,
    required this.zoneName,
    required this.code,
    required this.status,
    required this.mobileVerify,
    required this.ban,
    required this.createdOn,
    required this.updatedOn,
    required this.profileId,
    required this.address1,
    required this.address2,
    required this.state,
    required this.pincode,
    required this.city,
    required this.country,
     this.image,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] ?? '',
      userLevel: json['user_level'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      mobileCode: json['mobile_code'] ?? '',
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      profile: json['profile'],
      subscriptionId: json['subscription_id'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      locationName: json['location_name'] ?? '',
      zone: json['zone'] ?? '',
      zoneName: json['zone_name'] ?? '',
      code: json['code'] ?? '',
      status: json['status'] ?? '',
      mobileVerify: json['mobile_verify'] ?? '',
      ban: json['ban'] ?? '',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
      profileId: json['profile_id'] ?? '',
      address1: json['address1'] ?? '',
      address2: json['address2'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_level': userLevel,
      'username': username,
      'password': password,
      'email': email,
      'mobile_code': mobileCode,
      'mobile': mobile,
      'name': name,
      'profile': profile,
      'subscription_id': subscriptionId,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'zone': zone,
      'zone_name': zoneName,
      'code': code,
      'status': status,
      'mobile_verify': mobileVerify,
      'ban': ban,
      'created_on': createdOn,
      'updated_on': updatedOn,
      'profile_id': profileId,
      'address1': address1,
      'address2': address2,
      'state': state,
      'pincode': pincode,
      'city': city,
      'country': country,
      'image': image,
    };
  }
}
