import 'package:lelamonline_flutter/feature/categories/models/product_model.dart';
import 'package:lelamonline_flutter/feature/home/view/models/location_model.dart';

class ProductSearchService {
  final List<Product> products;
  final String searchQuery;
  final String selectedLocation;
  final String listingType;
  final List<String> selectedBrands;
  final String selectedPriceRange;
  final String selectedYearRange;
  final String selectedOwnersRange;
  final List<String> selectedFuelTypes;
  final List<String> selectedTransmissions;
  final String selectedKmRange;
  final String selectedSoldBy;
  final Map<String, Map<String, String>> postAttributeValuesCache;
  final List<LocationData> locations;

  ProductSearchService({
    required this.products,
    required this.searchQuery,
    required this.selectedLocation,
    required this.listingType,
    required this.selectedBrands,
    required this.selectedPriceRange,
    required this.selectedYearRange,
    required this.selectedOwnersRange,
    required this.selectedFuelTypes,
    required this.selectedTransmissions,
    required this.selectedKmRange,
    required this.selectedSoldBy,
    required this.postAttributeValuesCache,
    required this.locations,
    
  });

  String _getLocationName(String zoneId) {
    if (zoneId == 'all') return 'All Kerala';
    final location = locations.firstWhere(
      (loc) => loc.id == zoneId,
      orElse: () => LocationData(
        id: '',
        slug: '',
        parentId: '',
        name: zoneId,
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
    return location.name;
  }

  double _calculateRelevanceScore(Product product, String query) {
    final attributeValues = postAttributeValuesCache[product.id] ?? {};
    double score = 0;

    if (product.title.toLowerCase().contains(query)) score += 3.0;
    if (product.brand.toLowerCase().contains(query)) score += 2.0;
    if (product.model.toLowerCase().contains(query)) score += 1.5;
    if (product.modelVariation.toLowerCase().contains(query)) score += 1.0;
    if (_getLocationName(product.parentZoneId).toLowerCase().contains(query))
      score += 0.5;
    if ((attributeValues['Fuel Type']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Transmission']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Year']?.toLowerCase() ?? '').contains(query))
      score += 0.5;
    if ((attributeValues['Sold by']?.toLowerCase() ??
            (product.byDealer == '1' ? 'dealer' : 'owner'))
        .contains(query))
      score += 0.5;

    return score;
  }

  List<Product> searchProducts() {
    final filtered = products.where((product) {
      final attributeValues = postAttributeValuesCache[product.id] ?? {};

      // Search query filtering
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final searchableText = [
          product.title.toLowerCase(),
          product.brand.toLowerCase(),
          product.model.toLowerCase(),
          product.modelVariation.toLowerCase(),
          _getLocationName(product.parentZoneId).toLowerCase(),
          attributeValues['Fuel Type']?.toLowerCase() ?? '',
          attributeValues['Transmission']?.toLowerCase() ?? '',
          attributeValues['Year']?.toLowerCase() ?? '',
          attributeValues['Sold by']?.toLowerCase() ??
              (product.byDealer == '1' ? 'dealer' : 'owner'),
        ].join(' ');
        if (!searchableText.contains(query)) return false;
      }

      // Location filter
      if (selectedLocation != 'all' && product.parentZoneId != selectedLocation)
        return false;

      // Listing type filter
      if (listingType == 'auction' && product.ifAuction != '1') return false;
      if (listingType == 'Marketplace' && product.ifAuction != '0') return false;

      // Brand filter
      if (selectedBrands.isNotEmpty && !selectedBrands.contains(product.brand))
        return false;

      // Price range filter
      if (selectedPriceRange != 'all') {
        int price = product.ifAuction == '1'
            ? (int.tryParse(product.auctionStartingPrice) ?? 0)
            : (int.tryParse(product.price) ?? 0);
        switch (selectedPriceRange) {
          case 'Under ₹2 Lakh':
            if (price >= 200000) return false;
            break;
          case '₹2-5 Lakh':
            if (price < 200000 || price >= 500000) return false;
            break;
          case '₹5-10 Lakh':
            if (price < 500000 || price >= 1000000) return false;
            break;
          case '₹10-20 Lakh':
            if (price < 1000000 || price >= 2000000) return false;
            break;
          case 'Above ₹20 Lakh':
            if (price < 2000000) return false;
            break;
        }
      }

      // Year range filter
      final yearStr = attributeValues['Year'] ?? '0';
      final year = int.tryParse(yearStr) ?? 0;
      if (selectedYearRange != 'all') {
        switch (selectedYearRange) {
          case '2020 & Above':
            if (year < 2020) return false;
            break;
          case '2018-2019':
            if (year < 2018 || year > 2019) return false;
            break;
          case '2015-2017':
            if (year < 2015 || year > 2017) return false;
            break;
          case '2010-2014':
            if (year < 2010 || year > 2014) return false;
            break;
          case 'Below 2010':
            if (year >= 2010) return false;
            break;
        }
      }

      // Owners range filter
      final ownersStr = attributeValues['No of owners'] ?? '';
      int owners = 0;
      if (ownersStr.contains('1st'))
        owners = 1;
      else if (ownersStr.contains('2nd'))
        owners = 2;
      else if (ownersStr.contains('3rd'))
        owners = 3;
      else if (ownersStr.contains('4'))
        owners = 4;
      if (selectedOwnersRange != 'all') {
        switch (selectedOwnersRange) {
          case '1st Owner':
            if (owners != 1) return false;
            break;
          case '2nd Owner':
            if (owners != 2) return false;
            break;
          case '3rd Owner':
            if (owners != 3) return false;
            break;
          case '4+ Owners':
            if (owners < 4) return false;
            break;
        }
      }

      // Fuel type filter
      final fuel = attributeValues['Fuel Type'] ?? '';
      if (selectedFuelTypes.isNotEmpty && !selectedFuelTypes.contains(fuel))
        return false;

      // Transmission filter
      final trans = attributeValues['Transmission'] ?? '';
      if (selectedTransmissions.isNotEmpty && !selectedTransmissions.contains(trans))
        return false;

      // KM range filter
      final kmStr = attributeValues['KM Range'] ?? '';
      int km = 0;
      final kmMatch = RegExp(r'(\d+)').firstMatch(kmStr);
      if (kmMatch != null) km = int.tryParse(kmMatch.group(1) ?? '0') ?? 0;
      if (selectedKmRange != 'all') {
        switch (selectedKmRange) {
          case 'Under 10K':
            if (km >= 10000) return false;
            break;
          case '10K-30K':
            if (km < 10000 || km >= 30000) return false;
            break;
          case '30K-50K':
            if (km < 30000 || km >= 50000) return false;
            break;
          case '50K-80K':
            if (km < 50000 || km >= 80000) return false;
            break;
          case 'Above 80K':
            if (km < 80000) return false;
            break;
        }
      }

      // Sold by filter
      final soldBy = attributeValues['Sold by'] ?? (product.byDealer == '1' ? 'Dealer' : 'Owner');
      if (selectedSoldBy != 'all') {
        switch (selectedSoldBy) {
          case 'Owner':
            if (soldBy != 'Owner') return false;
            break;
          case 'Dealer':
          case 'Certified Dealer':
            if (soldBy != 'Dealer' && soldBy != 'Certified Dealer') return false;
            break;
        }
      }

      return true;
    }).toList();

    // Sort products based on search query relevance if search query exists
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, query);
        final bScore = _calculateRelevanceScore(b, query);
        return bScore.compareTo(aScore); // Higher score comes first
      });
    }

    return filtered;
  }
}