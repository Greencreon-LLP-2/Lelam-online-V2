import 'package:hive/hive.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';

class HiveHelper {
  static const String _boxName = 'userBox';
  static const String _userKey = 'userData';

  // Initialize Hive box
  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  // Save user data to Hive (store as JSON)
  Future<bool> saveUserData(UserData user) async {
    try {
      final box = await _openBox();
      await box.put(_userKey, user.toJson());

      // Verify the data was saved
      final savedData = box.get(_userKey);
      if (savedData != null) {
        return true; // Successfully saved
      } else {
        return false; // Failed to save
      }
    } catch (e) {
      // Handle any errors
      return false;
    }
  }

  // Fetch stored user data as UserData
  Future<UserData?> getUserData() async {
    final box = await _openBox();
    final Map<String, dynamic>? userMap =
        box.get(_userKey)?.cast<String, dynamic>();
    if (userMap != null) {
      return UserData.fromJson(userMap);
    }
    return null;
  }

  // Get user ID
  Future<String?> getUserId() async {
    final userData = await getUserData();
    return userData?.userId;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final userData = await getUserData();
    return userData != null && userData.userId.isNotEmpty;
  }

  // Clear user data (logout)
  Future<void> logout() async {
    final box = await _openBox();
    await box.delete(_userKey);
  }
}
