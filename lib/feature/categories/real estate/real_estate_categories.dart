import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class RealEstatePage extends StatefulWidget {
  const RealEstatePage({super.key});

  @override
  State<RealEstatePage> createState() => _RealEstatePageState();
}

class _RealEstatePageState extends State<RealEstatePage> {
  String _searchQuery = '';
  String _selectedPropertyType = 'all';
  String _selectedPriceRange = 'all';
  String _selectedLocation = 'all';
  String _selectedTransactionType = 'all';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _properties = List.generate(
    25,
    (index) => {
      'id': index + 1,
      'title': [
        '3BHK Apartment in Bandra',
        '2BHK Flat in Powai',
        'Villa in Lonavala',
        'Office Space in BKC',
        '1BHK Studio in Andheri',
        'Commercial Shop in Dadar',
        '4BHK Penthouse in Worli',
        'Independent House in Pune',
        'Warehouse in MIDC',
        'Plot in New Mumbai'
      ][index % 10],
      'type': [
        'Apartment',
        'Villa',
        'Office',
        'Shop',
        'House',
        'Plot',
        'Warehouse'
      ][index % 7],
      'transactionType': ['Sale', 'Rent'][index % 2],
      'price': index % 2 == 0 
        ? (index + 1) * 500000 + 2000000  // Sale price
        : (index + 1) * 15000 + 25000,    // Rent price
      'location': [
        'Mumbai',
        'Delhi',
        'Bangalore',
        'Chennai',
        'Pune',
        'Hyderabad',
        'Kolkata'
      ][index % 7],
      'area': (index + 1) * 200 + 800, // sq ft
      'bedrooms': (index % 4) + 1,
      'bathrooms': (index % 3) + 1,
      'furnishing': ['Furnished', 'Semi-Furnished', 'Unfurnished'][index % 3],
      'image': 'assets/images/property_${(index % 5) + 1}.jpg',
      'verified': index % 4 == 0,
      'featured': index % 6 == 0,
      'description': 'Beautiful property with modern amenities and excellent location connectivity.',
    },
  );

  final List<String> _propertyTypes = [
    'all', 'Apartment', 'Villa', 'House', 'Office', 'Shop', 'Plot', 'Warehouse'
  ];

  final List<String> _priceRanges = [
    'all', 'Under 50L', '50L-1Cr', '1Cr-2Cr', '2Cr-5Cr', 'Above 5Cr'
  ];

  final List<String> _locations = [
    'all', 'Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune', 'Hyderabad', 'Kolkata'
  ];

  final List<String> _transactionTypes = [
    'all', 'Sale', 'Rent'
  ];

  List<Map<String, dynamic>> get filteredProperties {
    List<Map<String, dynamic>> filtered = _properties;

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((property) {
        return property['title'].toString().toLowerCase().contains(query) ||
            property['location'].toString().toLowerCase().contains(query) ||
            property['type'].toString().toLowerCase().contains(query);
      }).toList();
    }

    // Property type filter
    if (_selectedPropertyType != 'all') {
      filtered = filtered.where((property) => property['type'] == _selectedPropertyType).toList();
    }

    // Location filter
    if (_selectedLocation != 'all') {
      filtered = filtered.where((property) => property['location'] == _selectedLocation).toList();
    }

    // Transaction type filter
    if (_selectedTransactionType != 'all') {
      filtered = filtered.where((property) => property['transactionType'] == _selectedTransactionType).toList();
    }

    // Price filter (only for sale properties)
    if (_selectedPriceRange != 'all' && _selectedTransactionType != 'Rent') {
      filtered = filtered.where((property) {
        if (property['transactionType'] == 'Rent') return true;
        
        final price = property['price'] as int;
        switch (_selectedPriceRange) {
          case 'Under 50L':
            return price < 5000000;
          case '50L-1Cr':
            return price >= 5000000 && price < 10000000;
          case '1Cr-2Cr':
            return price >= 10000000 && price < 20000000;
          case '2Cr-5Cr':
            return price >= 20000000 && price < 50000000;
          case 'Above 5Cr':
            return price >= 50000000;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildPropertiesGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 24),
              ),
              Expanded(
                child: Text(
                  'Real Estate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchAndFilters(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Box
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search properties, locations...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Filter Row 1
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _selectedTransactionType,
                items: _transactionTypes,
                hint: 'Sale/Rent',
                onChanged: (value) {
                  setState(() {
                    _selectedTransactionType = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedPropertyType,
                items: _propertyTypes,
                hint: 'Property Type',
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter Row 2
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _selectedPriceRange,
                items: _priceRanges,
                hint: 'Price Range',
                onChanged: (value) {
                  setState(() {
                    _selectedPriceRange = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedLocation,
                items: _locations,
                hint: 'Location',
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(hint),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(item == 'all' ? hint : item),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPropertiesGrid() {
    final properties = filteredProperties;

    if (properties.isEmpty) {
      return const Center(
        child: Text(
          'No properties found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.4,
        mainAxisSpacing: 16,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildPropertyCard(property);
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.productDetailsPage, extra: property);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Image
                Expanded(
                  flex: 2,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      child: Image.asset(
                        property['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Property',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Details
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: property['transactionType'] == 'Sale'
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                property['transactionType'],
                                style: TextStyle(
                                  color: property['transactionType'] == 'Sale'
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property['location'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.home,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property['type'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPropertyDetail(
                              Icons.bed,
                              '${property['bedrooms']} BHK',
                            ),
                            const SizedBox(width: 16),
                            _buildPropertyDetail(
                              Icons.bathtub,
                              '${property['bathrooms']} Bath',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPropertyDetail(
                              Icons.square_foot,
                              '${property['area']} sq ft',
                            ),
                            const SizedBox(width: 16),
                            _buildPropertyDetail(
                              Icons.chair,
                              property['furnishing'],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              property['transactionType'] == 'Sale'
                                  ? '₹${_formatPrice(property['price'])}'
                                  : '₹${_formatRent(property['price'])}/month',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Badges
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  if (property['featured'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (property['verified'] == true)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000000) {
      double crore = price / 10000000;
      if (crore == crore.round()) {
        return '${crore.round()} Cr';
      } else {
        return '${crore.toStringAsFixed(1)} Cr';
      }
    } else if (price >= 100000) {
      double lakh = price / 100000;
      if (lakh == lakh.round()) {
        return '${lakh.round()} L';
      } else {
        return '${lakh.toStringAsFixed(1)} L';
      }
    } else if (price >= 1000) {
      return '${(price / 1000).round()}K';
    } else {
      return price.toString();
    }
  }

  String _formatRent(int rent) {
    if (rent >= 100000) {
      double lakh = rent / 100000;
      return '${lakh.toStringAsFixed(1)}L';
    } else if (rent >= 1000) {
      return '${(rent / 1000).round()}K';
    } else {
      return rent.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}