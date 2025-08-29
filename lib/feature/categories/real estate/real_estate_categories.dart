import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class Property {
  final String id;
  final String slug;
  final String title;
  final String categoryId;
  final String image;
  final String type;
  final String propertyType;
  final String description;
  final String price;
  final Map<String, dynamic> filters;
  final String latitude;
  final String longitude;
  final String landMark;
  final String adminApproval;
  final String ifFinance;
  final String feature;
  final String status;
  final String visiterCount;
  final String ifSold;
  final String ifExpired;
  final String byDealer;
  final String createdBy;
  final String createdOn;
  final String updatedOn;

  Property({
    required this.id,
    required this.slug,
    required this.title,
    required this.categoryId,
    required this.image,
    required this.type,
    required this.propertyType,
    required this.description,
    required this.price,
    required this.filters,
    required this.latitude,
    required this.longitude,
    required this.landMark,
    required this.adminApproval,
    required this.ifFinance,
    required this.feature,
    required this.status,
    required this.visiterCount,
    required this.ifSold,
    required this.ifExpired,
    required this.byDealer,
    required this.createdBy,
    required this.createdOn,
    required this.updatedOn,
  });
}

class RealEstatePage extends StatefulWidget {
  const RealEstatePage({super.key});

  @override
  State<RealEstatePage> createState() => _RealEstatePageState();
}

class _RealEstatePageState extends State<RealEstatePage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';

  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  List<String> _selectedPropertyTypes = [];
  String _selectedPriceRange = 'all';
  String _selectedBedroomRange = 'all';
  String _selectedAreaRange = 'all';
  List<String> _selectedFurnishings = [];
  String _selectedPostedBy = 'all';

  late ScrollController _scrollController;
  bool _showAppBarSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && !_showAppBarSearch) {
      setState(() => _showAppBarSearch = true);
    } else if (_scrollController.offset <= 100 && _showAppBarSearch) {
      setState(() => _showAppBarSearch = false);
    }
  }

  final List<Property> _properties = List.generate(
    20,
    (index) => Property(
      id: '${index + 1}',
      slug: 'property-${index + 1}',
      title:
          [
            'Modern 3BHK Apartment',
            'Luxury Villa with Pool',
            'Commercial Office Space',
            'Prime Location Shop',
            'Beachfront Villa',
            '2BHK Premium Flat',
            'Penthouse with Terrace',
            'Family Independent House',
            'Warehouse Space',
            'Farmhouse with Garden',
            'Studio Apartment',
            'Duplex Villa',
            'Industrial Plot',
            'Residential Plot',
            'Apartment for Rent',
            'Luxury Apartment',
            'Villa with Sea View',
            'Office Space in CBD',
            'Retail Shop',
            'Bungalow with Garden',
          ][index % 20],
      categoryId: 'real-estate',
      image: 'assets/images/property_${(index % 5) + 1}.jpg',
      type: ['Residential', 'Commercial', 'Industrial'][index % 3],
      propertyType:
          [
            'Apartment',
            'Villa',
            'Office',
            'Shop',
            'House',
            'Penthouse',
            'Duplex',
            'Warehouse',
            'Plot',
            'Farmhouse',
          ][index % 10],
      description:
          'Beautiful property with modern amenities and excellent location connectivity.',
      price: '${(index + 1) * 500000 + 2000000}',
      filters: {
        'bedrooms': '${(index % 5) + 1}',
        'bathrooms': '${(index % 4) + 1}',
        'area': '${(index + 1) * 200 + 800}',
        'furnishing': ['Furnished', 'Semi-Furnished', 'Unfurnished'][index % 3],
        'floor': '${(index % 10) + 1}',
        'totalFloors': '${(index % 5) + 5}',
        'age': '${(index % 10) + 1}',
      },
      latitude: '19.0760',
      longitude: '72.8777',
      landMark:
          [
            'Ernakulam',
            'Idukki',
            'Kannur',
            'Kasaragod',
            'Kollam',
            'Kottayam',
            'Kozhikode',
            'Malappuram',
            'Palakkad',
            'Pathanamthitta',
            'Thiruvananthapuram',
            'Thrissur',
            'Wayanad',
          ][index % 13],
      adminApproval: '1',
      ifFinance: index % 3 == 0 ? '1' : '0',
      feature: index % 5 == 0 ? '1' : '0',
      status: '1',
      visiterCount: '${(index + 1) * 15}',
      ifSold: '0',
      ifExpired: '0',
      byDealer: ['0', '1', '1'][index % 3],
      createdBy: 'user_${index + 1}',
      createdOn:
          DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      updatedOn:
          DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
    ),
  );

  final List<String> _propertyTypes = [
    'Apartment',
    'Villa',
    'House',
    'Office',
    'Shop',
    'Penthouse',
    'Duplex',
    'Warehouse',
    'Plot',
    'Farmhouse',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under 50L',
    '50L-1Cr',
    '1Cr-2Cr',
    '2Cr-5Cr',
    'Above 5Cr',
  ];

  final List<String> _bedroomRanges = ['all', '1', '2', '3', '4', '5+'];

  final List<String> _areaRanges = [
    'all',
    'Under 500 sq ft',
    '500-1000 sq ft',
    '1000-1500 sq ft',
    '1500-2000 sq ft',
    'Above 2000 sq ft',
  ];

  final List<String> _furnishings = [
    'Furnished',
    'Semi-Furnished',
    'Unfurnished',
  ];

  final List<String> _postedByOptions = ['all', 'Owner', 'Builder', 'Agent'];

  final List<String> _districts = [
    'all',
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  List<Property> get filteredProperties {
    List<Property> filtered = _properties;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((property) {
            return property.title.toLowerCase().contains(query) ||
                property.landMark.toLowerCase().contains(query) ||
                property.propertyType.toLowerCase().contains(query);
          }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((property) => property.landMark == _selectedLocation)
              .toList();
    }

    if (_selectedPropertyTypes.isNotEmpty) {
      filtered =
          filtered
              .where(
                (property) => _selectedPropertyTypes.contains(property.type),
              )
              .toList();
    }

    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((property) {
            int price = int.tryParse(property.price) ?? 0;
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

    if (_selectedBedroomRange != 'all') {
      filtered =
          filtered.where((property) {
            int bedrooms =
                int.tryParse(property.filters['bedrooms']?.toString() ?? '0') ??
                0;
            switch (_selectedBedroomRange) {
              case '1':
                return bedrooms == 1;
              case '2':
                return bedrooms == 2;
              case '3':
                return bedrooms == 3;
              case '4':
                return bedrooms == 4;
              case '5+':
                return bedrooms >= 5;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedAreaRange != 'all') {
      filtered =
          filtered.where((property) {
            int area =
                int.tryParse(property.filters['area']?.toString() ?? '0') ?? 0;
            switch (_selectedAreaRange) {
              case 'Under 500 sq ft':
                return area < 500;
              case '500-1000 sq ft':
                return area >= 500 && area < 1000;
              case '1000-1500 sq ft':
                return area >= 1000 && area < 1500;
              case '1500-2000 sq ft':
                return area >= 1500 && area < 2000;
              case 'Above 2000 sq ft':
                return area >= 2000;
              default:
                return true;
            }
          }).toList();
    }

    if (_selectedFurnishings.isNotEmpty) {
      filtered =
          filtered
              .where(
                (property) => _selectedFurnishings.contains(
                  property.filters['furnishing'],
                ),
              )
              .toList();
    }

    if (_selectedPostedBy != 'all') {
      filtered =
          filtered.where((property) {
            switch (_selectedPostedBy) {
              case 'Owner':
                return property.byDealer == '0';
              case 'Builder':
              case 'Agent':
                return property.byDealer == '1';
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filter Properties',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedPropertyTypes.clear();
                                  _selectedPriceRange = 'all';
                                  _selectedBedroomRange = 'all';
                                  _selectedAreaRange = 'all';
                                  _selectedFurnishings.clear();
                                  _selectedPostedBy = 'all';
                                });
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMultiSelectFilterSection(
                                'Property Type',
                                _propertyTypes,
                                _selectedPropertyTypes,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'Price Range',
                                _priceRanges,
                                _selectedPriceRange,
                                (value) => setModalState(
                                  () => _selectedPriceRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Bedrooms',
                                _bedroomRanges,
                                _selectedBedroomRange,
                                (value) => setModalState(
                                  () => _selectedBedroomRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Area',
                                _areaRanges,
                                _selectedAreaRange,
                                (value) => setModalState(
                                  () => _selectedAreaRange = value,
                                ),
                              ),
                              _buildMultiSelectFilterSection(
                                'Furnishing',
                                _furnishings,
                                _selectedFurnishings,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'Posted By',
                                _postedByOptions,
                                _selectedPostedBy,
                                (value) => setModalState(
                                  () => _selectedPostedBy = value,
                                ),
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primarypink,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.primaryblue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildMultiSelectFilterSection(
    String title,
    List<String> options,
    List<String> selectedValues,
    StateSetter setModalState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = selectedValues.contains(option);
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      if (isSelected) {
                        selectedValues.remove(option);
                      } else {
                        selectedValues.add(option);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Palette.primarypink
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Palette.primarypink
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleSelectFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = selectedValue == option;
                final displayText = option == 'all' ? 'Any $title' : option;
                return GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Palette.primarypink
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Palette.primarypink
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedPropertyTypes.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedBedroomRange != 'all') count++;
    if (_selectedAreaRange != 'all') count++;
    if (_selectedFurnishings.isNotEmpty) count++;
    if (_selectedPostedBy != 'all') count++;
    return count;
  }

  Widget _buildAppBarSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Search properties...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by property type, location, features...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
        suffixIcon:
            _searchQuery.isNotEmpty
                ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: _showAppBarSearch ? _buildAppBarSearchField() : null,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune, color: Colors.black87),
              ),
              if (_getActiveFilterCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on, color: Colors.black87),
            onSelected: (String value) {
              setState(() {
                _selectedLocation = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _districts.map((String district) {
                return PopupMenuItem<String>(
                  value: district,
                  child: Row(
                    children: [
                      if (_selectedLocation == district)
                        const Icon(Icons.check, color: Colors.blue, size: 16),
                      if (_selectedLocation == district)
                        const SizedBox(width: 8),
                      Text(district == 'all' ? 'All Kerala' : district),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showAppBarSearch)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchField(),
            ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16),
              children: [
                for (var property in filteredProperties)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPropertyCard(property),
                  ),
                if (filteredProperties.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final isFinanceAvailable = property.ifFinance == '1';
    final isFeatured = property.feature == '1';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            // Navigation to property details page can be added here
          },
          child: Container(
            width: constraints.maxWidth,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(
                        width: 120,
                        height: 138,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(0),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                              child: Image.asset(
                                property.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.home,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isFeatured)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              property.propertyType,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹ ${formatPriceInt(double.tryParse(property.price) ?? 0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Palette.primaryblue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  property.landMark,
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
                                _buildDetailChip(
                                  Icon(
                                    Icons.bed,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  '${property.filters['bedrooms']} Beds',
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.bathtub,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  '${property.filters['bathrooms']} Baths',
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.aspect_ratio,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  '${_formatNumber(int.tryParse(property.filters['area']?.toString() ?? '0') ?? 0)} sq ft',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildDetailChip(
                                  Icon(
                                    Icons.chair,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  '${property.filters['furnishing']}',
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.apartment,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  'Floor ${property.filters['floor']}/${property.filters['totalFloors']}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isFinanceAvailable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.primarylightblue,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Finance Available',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(Widget icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  String formatPriceInt(double price) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return formatter.format(price.round());
  }

  String _formatNumber(num number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(number == number.roundToDouble() ? 0 : 2);
    }
  }
}
