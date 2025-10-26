// lib/core/service/core_data_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:lelamonline_flutter/core/service/coredata_service.dart';
import '../model/core_data_model.dart';

class CoreDataNotifier with ChangeNotifier {
  final CoreDataService _service = CoreDataService();
  
  CoreDataModel? _coreData;
  bool _isLoading = false;
  String? _error;
  String? _token;

  CoreDataModel? get coreData => _coreData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _coreData != null;

  // Get specific properties with fallbacks
  String get siteTitle => _coreData?.siteTitle ?? 'Lelam Online';
  String get logoUrl => _coreData?.logo ?? '';
  String get appLogoUrl => _coreData?.appLogo ?? '';
  String? get googleMapApi => _coreData?.googleMapAPI;
  bool get isGoogleMapEnabled => _coreData?.ifGoogleMap ?? true;
  bool get isPhonePeEnabled => _coreData?.ifPhonepe ?? false;
  bool get isQrCodePaymentEnabled => _coreData?.ifQrcodePayment ?? false;

  void setToken(String token) {
    _token = token;
  }

  Future<void> loadCoreData() async {
    if (_isLoading || _token == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coreData = await _service.fetchCoreData(token: _token!);
      if (_coreData == null) {
        _error = 'Failed to load core data';
      }
    } catch (e) {
      _error = 'Error loading core data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCoreData() async {
    if (_token != null) {
      await loadCoreData();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setCoreData(CoreDataModel data) {
    _coreData = data;
    notifyListeners();
  }

  // Helper method to get complete image URL
  String getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${_coreData?.siteUrl ?? 'https://lelamonline.com'}/$imagePath';
  }
}