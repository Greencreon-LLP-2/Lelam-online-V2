import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class CommercialVehiclesPage extends StatefulWidget {
  const CommercialVehiclesPage({super.key});

  @override
  State<CommercialVehiclesPage> createState() => _CommercialVehiclesPageState();
}

class _CommercialVehiclesPageState extends State<CommercialVehiclesPage> {
  String _searchQuery = '';
  String _selectedVehicleType = 'all';
  String _selectedPriceRange = 'all';
  String _selectedLocation = 'all';
  String _selectedCondition = 'all';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _commercialVehicles = List.generate(
    20,
    (index) => {
      'id': index + 1,
      'name':
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
      'type':
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
      'year': 2018 + (index % 6),
      'km': (index + 1) * 20000,
      'price': (index + 1) * 80000 + 300000,
      'location':
          [
            'Mumbai',
            'Delhi',
            'Bangalore',
            'Chennai',
            'Pune',
            'Ahmedabad',
            'Surat',
            'Hyderabad',
          ][index % 8],
      'brand':
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
      'fuel': ['Diesel', 'CNG', 'Petrol'][index % 3],
      'loadCapacity': '${((index % 10) + 1) * 500}kg',
      'condition': ['New', 'Used'][index % 2],
      'image': 'assets/images/commercial_${(index % 5) + 1}.jpg',
      'verified': index % 4 == 0,
      'featured': index % 7 == 0,
      'description':
          'Commercial vehicle in excellent condition with all papers clear.',
      'owner': index % 3 == 0 ? 'First Owner' : 'Second Owner',
      'transmission': 'Manual',
    },
  );

  final List<String> _vehicleTypes = [
    'all',
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
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Pune',
    'Ahmedabad',
    'Surat',
    'Hyderabad',
  ];

  final List<String> _conditions = ['all', 'New', 'Used'];

  List<Map<String, dynamic>> get filteredVehicles {
    List<Map<String, dynamic>> filtered = _commercialVehicles;

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((vehicle) {
            return vehicle['name'].toString().toLowerCase().contains(query) ||
                vehicle['brand'].toString().toLowerCase().contains(query) ||
                vehicle['type'].toString().toLowerCase().contains(query) ||
                vehicle['location'].toString().toLowerCase().contains(query);
          }).toList();
    }

    // Vehicle type filter
    if (_selectedVehicleType != 'all') {
      filtered =
          filtered
              .where((vehicle) => vehicle['type'] == _selectedVehicleType)
              .toList();
    }

    // Location filter
    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((vehicle) => vehicle['location'] == _selectedLocation)
              .toList();
    }

    // Condition filter
    if (_selectedCondition != 'all') {
      filtered =
          filtered
              .where((vehicle) => vehicle['condition'] == _selectedCondition)
              .toList();
    }

    // Price filter
    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((vehicle) {
            final price = vehicle['price'] as int;
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
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [_buildHeader(), Expanded(child: _buildVehiclesGrid())],
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
                  'Commercial Vehicles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    foreground:
                        Paint()
                          ..shader = LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade800,
                            ],
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                          ),
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
            hintText: 'Search vehicles, brands, types...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
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
                value: _selectedVehicleType,
                items: _vehicleTypes,
                hint: 'Vehicle Type',
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleType = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _selectedCondition,
                items: _conditions,
                hint: 'Condition',
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
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
          items:
              items.map((String item) {
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

  Widget _buildVehiclesGrid() {
    final vehicles = filteredVehicles;

    if (vehicles.isEmpty) {
      return const Center(
        child: Text(
          'No vehicles found',
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
        childAspectRatio: 1.3,
        mainAxisSpacing: 16,
      ),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(RouteNames.productDetailsPage, extra: vehicle);
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
                        vehicle['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Vehicle',
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
                                '${vehicle['year']} ${vehicle['name']}',
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
                                color:
                                    vehicle['condition'] == 'New'
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vehicle['condition'],
                                style: TextStyle(
                                  color:
                                      vehicle['condition'] == 'New'
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
                              vehicle['location'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.local_shipping,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vehicle['type'],
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
                            _buildVehicleDetail(
                              Icons.speed,
                              '${vehicle['km']} km',
                            ),
                            const SizedBox(width: 16),
                            _buildVehicleDetail(
                              Icons.local_gas_station,
                              vehicle['fuel'],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildVehicleDetail(
                              Icons.fitness_center,
                              vehicle['loadCapacity'],
                            ),
                            const SizedBox(width: 16),
                            _buildVehicleDetail(Icons.person, vehicle['owner']),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${_formatPrice(vehicle['price'])}',
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
                  if (vehicle['featured'] == true)
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
                  if (vehicle['verified'] == true)
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

  Widget _buildVehicleDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
