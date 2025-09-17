import 'package:hive/hive.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';

class HiveHelper {
  static const String _boxName = 'userBox';
  static const String _userKey = 'userData';
  static const String _hasShownNameDialogKey = 'has_shown_name_dialog';

  // Ensure box is initialized only once
  Box? _box;

  // Initialize Hive box
  Future<Box> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  // Save user data to Hive (store as JSON)
  Future<bool> saveUserData(UserData user) async {
    try {
      final box = await _openBox();
      await box.put(_userKey, user.toJson());

      // Verify the data was saved
      final savedData = box.get(_userKey);
      if (savedData != null) {
        print('HiveHelper: User data saved successfully for userId: ${user.userId}');
        return true; // Successfully saved
      } else {
        print('HiveHelper: Failed to verify saved user data');
        return false; // Failed to save
      }
    } catch (e, stack) {
      print('HiveHelper: Error saving user data: $e');
      print(stack);
      return false;
    }
  }

  // Fetch stored user data as UserData
  Future<UserData?> getUserData() async {
    try {
      final box = await _openBox();
      final Map<String, dynamic>? userMap = box.get(_userKey)?.cast<String, dynamic>();
      if (userMap != null) {
        print('HiveHelper: User data retrieved successfully');
        return UserData.fromJson(userMap);
      } else {
        print('HiveHelper: No user data found in Hive');
        return null;
      }
    } catch (e, stack) {
      print('HiveHelper: Error retrieving user data: $e');
      print(stack);
      return null;
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      final userData = await getUserData();
      final userId = userData?.userId;
      print('HiveHelper: Retrieved userId: $userId');
      return userId;
    } catch (e, stack) {
      print('HiveHelper: Error retrieving userId: $e');
      print(stack);
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final userData = await getUserData();
      final isLoggedIn = userData != null && userData.userId.isNotEmpty;
      print('HiveHelper: isLoggedIn: $isLoggedIn');
      return isLoggedIn;
    } catch (e, stack) {
      print('HiveHelper: Error checking login status: $e');
      print(stack);
      return false;
    }
  }

  // Clear user data (logout)
  Future<void> logout() async {
    try {
      final box = await _openBox();
      await box.delete(_userKey);
      await box.delete(_hasShownNameDialogKey); // Clear name dialog flag on logout
      print('HiveHelper: User data and name dialog flag cleared successfully');
    } catch (e, stack) {
      print('HiveHelper: Error during logout: $e');
      print(stack);
    }
  }

  // Save hasShownNameDialog flag
  Future<void> setHasShownNameDialog(bool value) async {
    try {
      final box = await _openBox();
      await box.put(_hasShownNameDialogKey, value);
      print('HiveHelper: hasShownNameDialog set to $value');
    } catch (e, stack) {
      print('HiveHelper: Error saving hasShownNameDialog: $e');
      print(stack);
    }
  }

  // Retrieve hasShownNameDialog flag
  Future<bool> getHasShownNameDialog() async {
    try {
      final box = await _openBox();
      final value = box.get(_hasShownNameDialogKey, defaultValue: false) as bool;
      print('HiveHelper: Retrieved hasShownNameDialog: $value');
      return value;
    } catch (e, stack) {
      print('HiveHelper: Error retrieving hasShownNameDialog: $e');
      print(stack);
      return false;
    }
  }
}