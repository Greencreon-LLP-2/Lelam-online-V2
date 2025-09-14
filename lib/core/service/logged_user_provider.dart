import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/service/hive_helper.dart';

class LoggedUserProvider extends ChangeNotifier {
  UserData? _userData;

  UserData? get userData => _userData;

  // Initialize from Hive
  Future<void> loadUser() async {
    _userData = await HiveHelper().getUserData();
    notifyListeners();
  }

  // Update after login
  Future<void> setUser(UserData user) async {
    _userData = user;
    await HiveHelper().saveUserData(user);
    notifyListeners();
  }

  // Logout
  Future<void> clearUser() async {
    _userData = null;
    await HiveHelper().logout();
    notifyListeners();
  }

  bool get isLoggedIn => _userData != null && _userData!.userId.isNotEmpty;
}
