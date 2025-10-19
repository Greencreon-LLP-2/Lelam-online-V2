import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';

class LocationProvider with ChangeNotifier {
  String _selectedLocationName = 'All Kerala';
  String _selectedLocationId = 'all';
  List<LocationData> _locations = [];

  LocationProvider() {
    _loadSelectedLocation();
  }

  String get selectedLocationId => _selectedLocationId;
  String get selectedLocationName => _selectedLocationName;
  List<String> get districts => ['All Kerala', ..._locations.map((loc) => loc.name)];

  Future<void> setSelectedLocation(String name, {String? id}) async {
    _selectedLocationName = name;
    _selectedLocationId = id ?? (name == 'All Kerala' ? 'all' : name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_location_name', _selectedLocationName);
    await prefs.setString('selected_location_id', _selectedLocationId);
    notifyListeners();
  }

  void setLocations(List<LocationData> locations) {
    _locations = locations;
    notifyListeners();
  }

  Future<void> _loadSelectedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('selected_location_name');
    final savedId = prefs.getString('selected_location_id');
    if (savedName != null && savedId != null) {
      _selectedLocationName = savedName;
      _selectedLocationId = savedId;
      notifyListeners();
    }
  }

  String getLocationIdByName(String name) {
    if (name == 'All Kerala') return 'all';
    final location = _locations.firstWhere(
      (loc) => loc.name == name,
      orElse: () => LocationData(
        id: name,
        slug: '',
        parentId: '',
        name: name,
        image: '',
        description: '',
        latitude: '',
        longitude: '',
        popular: '',
        status: '',
        allStoreOnOff: '',
        createdOn: '',
        updatedOn: '',
      ),
    );
    return location.id;
  }
}