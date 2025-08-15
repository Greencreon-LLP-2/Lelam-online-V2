import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class Vehicle {
  final String id;
  final String name;
  final String type;
  final String year;
  final String km;
  final String price;
  final String location;
  final String brand;
  final String fuel;
  final String loadCapacity;
  final String condition;
  final String image;
  final String verified;
  final String featured;
  final String description;
  final String owner;
  final String transmission;
  final String ifFinance;

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.year,
    required this.km,
    required this.price,
    required this.location,
    required this.brand,
    required this.fuel,
    required this.loadCapacity,
    required this.condition,
    required this.image,
    required this.verified,
    required this.featured,
    required this.description,
    required this.owner,
    required this.transmission,
    required this.ifFinance,
  });
}

class CommercialVehiclesPage extends StatefulWidget {
  const CommercialVehiclesPage({super.key});

  @override
  State<CommercialVehiclesPage> createState() => _CommercialVehiclesPageState();
}

class _CommercialVehiclesPageState extends State<CommercialVehiclesPage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  List<String> _selectedVehicleTypes = [];
  String _selectedPriceRange = 'all';
  String _selectedCondition = 'all';
  List<String> _selectedFuelTypes = [];

  final TextEditingController _searchController = TextEditingController();
  
  // NEW: Scroll controller and search bar visibility
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
    // Show app bar search when scrolled beyond threshold
    if (_scrollController.offset > 100 && !_showAppBarSearch) {
      setState(() => _showAppBarSearch = true);
    } 
    // Hide app bar search when scrolled back to top
    else if (_scrollController.offset <= 100 && _showAppBarSearch) {
      setState(() => _showAppBarSearch = false);
    }
  }

  final List<Vehicle> _vehicles = List.generate(
    20,
    (index) => Vehicle(
      id: '${index + 1}',
      name:
          [
            'Tata Ace Gold',
            'Mahindra Bolero Pickup',
            'Ashok Leyland Dost',
            'Tata 407 Light Truck',
            'Mahindra Jeeto',
            'Force Traveller',
            'Tata Ultra T7',
            'Bajaj RE Auto',
            'Maruti Super Carry',
            'Isuzu D-MAX',
          ][index % 10],
      type:
          [
            'Mini Truck',
            'Pickup Truck',
            'Light Truck',
            'Bus',
            'Auto Rickshaw',
            'Tempo',
            'Heavy Truck',
            'Van',
          ][index % 8],
      year: '${2018 + (index % 6)}',
      km: '${(index + 1) * 20000}',
      price: '${(index + 1) * 80000 + 300000}',
      location:
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
          ][index % 8],
      brand:
          [
            'Tata',
            'Mahindra',
            'Ashok Leyland',
            'Force',
            'Bajaj',
            'Maruti',
            'Isuzu',
            'Eicher',
          ][index % 8],
      fuel: ['Diesel', 'CNG', 'Petrol'][index % 3],
      loadCapacity: '${((index % 10) + 1) * 500}kg',
      condition: ['New', 'Used'][index % 2],
      image: 'assets/images/commercial_${(index % 5) + 1}.jpg',
      verified: index % 4 == 0 ? '1' : '0',
      featured: index % 7 == 0 ? '1' : '0',
      description:
          'Commercial vehicle in excellent condition with all papers clear.',
      owner: index % 3 == 0 ? 'First Owner' : 'Second Owner',
      transmission: 'Manual',
      ifFinance: index < 2 ? '1' : '0',
    ),
  );

  final List<String> _vehicleTypes = [
    'Mini Truck',
    'Pickup Truck',
    'Light Truck',
    'Heavy Truck',
    'Bus',
    'Auto Rickshaw',
    'Tempo',
    'Van',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under 5L',
    '5L-10L',
    '10L-20L',
    '20L-50L',
    'Above 50L',
  ];

  final List<String> _locations = [
    'all',
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
  ];

  final List<String> _conditions = ['all', 'New', 'Used'];

  final List<String> _fuelTypes = ['Diesel', 'CNG', 'Petrol'];

  List<Vehicle> get filteredVehicles {
    List<Vehicle> filtered = _vehicles;

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((vehicle) {
            return vehicle.name.toLowerCase().contains(query) ||
                vehicle.brand.toLowerCase().contains(query) ||
                vehicle.type.toLowerCase().contains(query) ||
                vehicle.location.toLowerCase().contains(query);
          }).toList();
    }

    // Location filter
    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((vehicle) => vehicle.location == _selectedLocation)
              .toList();
    }

    // Vehicle type filter
    if (_selectedVehicleTypes.isNotEmpty) {
      filtered =
          filtered
              .where((vehicle) => _selectedVehicleTypes.contains(vehicle.type))
              .toList();
    }

    // Price filter
    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((vehicle) {
            final price = int.tryParse(vehicle.price) ?? 0;
            switch (_selectedPriceRange) {
              case 'Under 5L':
                return price < 500000;
              case '5L-10L':
                return price >= 500000 && price < 1000000;
              case '10L-20L':
                return price >= 1000000 && price < 2000000;
              case '20L-50L':
                return price >= 2000000 && price < 5000000;
              case 'Above 50L':
                return price >= 5000000;
              default:
                return true;
            }
          }).toList();
    }

    // Condition filter
    if (_selectedCondition != 'all') {
      filtered =
          filtered
              .where((vehicle) => vehicle.condition == _selectedCondition)
              .toList();
    }

    // Fuel type filter
    if (_selectedFuelTypes.isNotEmpty) {
      filtered =
          filtered
              .where((vehicle) => _selectedFuelTypes.contains(vehicle.fuel))
              .toList();
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
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filter Vehicles',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedVehicleTypes.clear();
                                  _selectedPriceRange = 'all';
                                  _selectedCondition = 'all';
                                  _selectedFuelTypes.clear();
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

                      // Filters Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMultiSelectFilterSection(
                                'Vehicle Type',
                                _vehicleTypes,
                                _selectedVehicleTypes,
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
                                'Condition',
                                _conditions,
                                _selectedCondition,
                                (value) => setModalState(
                                  () => _selectedCondition = value,
                                ),
                              ),
                              _buildMultiSelectFilterSection(
                                'Fuel Type',
                                _fuelTypes,
                                _selectedFuelTypes,
                                setModalState,
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),

                      // Apply Button
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
                            // Cancel Button
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
                            // Apply Filters Button
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
    if (_selectedVehicleTypes.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedCondition != 'all') count++;
    if (_selectedFuelTypes.isNotEmpty) count++;
    return count;
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
              return _locations.map((String location) {
                return PopupMenuItem<String>(
                  value: location,
                  child: Row(
                    children: [
                      if (_selectedLocation == location)
                        const Icon(Icons.check, color: Colors.blue, size: 16),
                      if (_selectedLocation == location)
                        const SizedBox(width: 8),
                      Text(location == 'all' ? 'All Kerala' : location),
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
          // Search Bar (only shown when not in app bar)
          if (!_showAppBarSearch) 
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSearchField(),
            ),

          // Vehicles List (with scroll controller)
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                for (var vehicle in filteredVehicles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildVehicleCard(vehicle),
                  ),
                if (filteredVehicles.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No vehicles found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or search terms',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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

  // Build the search field for the app bar
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
          hintText: 'Search vehicles...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
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

  // Build the main search field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by vehicle type, brand, location...',
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

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isFinanceAvailable = vehicle.ifFinance == '1';
    final isFeatured = vehicle.featured == '1';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Image
              Container(
                width: 140,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(0),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.asset(
                        vehicle.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.local_shipping,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
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
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (vehicle.verified == '1')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Vehicle Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Vehicle Type
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        vehicle.type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price
                      Text(
                        '₹${_formatPrice(int.tryParse(vehicle.price) ?? 0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Palette.primaryblue,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Vehicle Details Row (Year, Condition, Fuel)
                      Row(
                        children: [
                          _buildDetailChip(
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            vehicle.year,
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.construction,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            vehicle.condition,
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.local_gas_station,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            vehicle.fuel,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          _buildDetailChip(
                            Icon(
                              Icons.speed,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            '${_formatNumber(int.tryParse(vehicle.km) ?? 0)} km',
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.inventory,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            vehicle.loadCapacity,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom section with finance info
          if (isFinanceAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Icon(Icons.account_balance, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Finance Available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(Widget icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000000) {
      double crore = price / 10000000;
      return '${crore.toStringAsFixed(crore == crore.round() ? 0 : 2)} Crore';
    } else if (price >= 100000) {
      double lakh = price / 100000;
      return '${lakh.toStringAsFixed(lakh == lakh.round() ? 0 : 2)} Lakh';
    } else if (price >= 1000) {
      double thousand = price / 1000;
      return '${thousand.toStringAsFixed(thousand == thousand.round() ? 0 : 1)}K';
    } else {
      return price.toString();
    }
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).round()}K';
    } else {
      return number.toString();
    }
  }
}