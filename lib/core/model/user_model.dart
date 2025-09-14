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
    };
  }
}