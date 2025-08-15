import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

// Placeholder Product model (replace with your actual Product model)
class Product {
  final String id;
  final String slug;
  final String title;
  final String categoryId;
  final String image;
  final String brand;
  final String model;
  final String modelVariation;
  final String description;
  final String price;
  final String auctionPriceIntervel;
  final String auctionStartingPrice;
  final List<String> attributeId;
  final List<String> attributeVariationsId;
  final Map<String, String> filters;
  final String latitude;
  final String longitude;
  final String userZoneId;
  final String parentZoneId;
  final String zoneId;
  final String landMark;
  final String ifAuction;
  final String auctionStatus;
  final String auctionStartin;
  final String auctionEndin;
  final String auctionAttempt;
  final String adminApproval;
  final String ifFinance;
  final String ifExchange;
  final String feature;
  final String status;
  final String visiterCount;
  final String ifSold;
  final String ifExpired;
  final String byDealer;
  final String createdBy;
  final String createdOn;
  final String updatedOn;

  Product({
    required this.id,
    required this.slug,
    required this.title,
    required this.categoryId,
    required this.image,
    required this.brand,
    required this.model,
    required this.modelVariation,
    required this.description,
    required this.price,
    required this.auctionPriceIntervel,
    required this.auctionStartingPrice,
    required this.attributeId,
    required this.attributeVariationsId,
    required this.filters,
    required this.latitude,
    required this.longitude,
    required this.userZoneId,
    required this.parentZoneId,
    required this.zoneId,
    required this.landMark,
    required this.ifAuction,
    required this.auctionStatus,
    required this.auctionStartin,
    required this.auctionEndin,
    required this.auctionAttempt,
    required this.adminApproval,
    required this.ifFinance,
    required this.ifExchange,
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

class UsedCarsPage extends StatefulWidget {
  const UsedCarsPage({super.key});

  @override
  State<UsedCarsPage> createState() => _UsedCarsPageState();
}

class _UsedCarsPageState extends State<UsedCarsPage> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  String _listingType = 'sale';

  final TextEditingController _searchController = TextEditingController();

  // Filter variables
  List<String> _selectedBrands = [];
  String _selectedPriceRange = 'all';
  String _selectedYearRange = 'all';
  String _selectedOwnersRange = 'all';
  List<String> _selectedFuelTypes = [];
  List<String> _selectedTransmissions = [];
  String _selectedKmRange = 'all';
  String _selectedSoldBy = 'all';

  final List<Product> _products = List.generate(
    30, // Increased from 20 to 30 for more auction products
    (index) => Product(
      id: '${index + 1}',
      slug: 'car-${index + 1}',
      title:
          [
            'Hyundai Grand i10 Nios',
            'Hyundai i10',
            'Tata Tiago',
            'Maruti Swift VDi',
            'Toyota Camry Hybrid',
            'BMW 320d Sport',
            'Audi A4 Premium',
            'Ford EcoSport Titanium',
            'Mahindra XUV500 W8',
            'Volkswagen Polo GT',
            'Honda City VTi',
            'Maruti Baleno Delta',
            'Hyundai Creta SX',
            'Tata Harrier XZ+',
            'Kia Seltos HTK+',
            'Maruti Alto K10',
            'Honda Jazz VX',
            'Toyota Innova Crysta',
            'Mahindra Scorpio S11',
            'Hyundai Venue SX',
            'Tata Nexon XZ+',
            'Ford Figo Titanium',
            'Maruti Wagon R VXI',
            'Hyundai Elantra SX',
            'BMW X1 sDrive20d',
            'Audi Q3 Premium Plus',
            'Mercedes C-Class',
            'Skoda Rapid Monte Carlo',
            'Volkswagen Vento Highline',
            'Nissan Kicks XV',
          ][index % 30],
      categoryId: 'used-cars',
      image: 'assets/images/used_car_${(index % 5) + 1}.jpg',
      brand:
          [
            'Hyundai',
            'Hyundai',
            'Tata',
            'Maruti',
            'Toyota',
            'BMW',
            'Audi',
            'Ford',
            'Mahindra',
            'Volkswagen',
            'Honda',
            'Maruti',
            'Hyundai',
            'Tata',
            'Kia',
            'Maruti',
            'Honda',
            'Toyota',
            'Mahindra',
            'Hyundai',
            'Tata',
            'Ford',
            'Maruti',
            'Hyundai',
            'BMW',
            'Audi',
            'Mercedes',
            'Skoda',
            'Volkswagen',
            'Nissan',
          ][index % 30],
      model:
          [
            'Grand i10 Nios',
            'i10',
            'Tiago',
            'Swift',
            'Camry',
            '320d',
            'A4',
            'EcoSport',
            'XUV500',
            'Polo',
            'City',
            'Baleno',
            'Creta',
            'Harrier',
            'Seltos',
            'Alto K10',
            'Jazz',
            'Innova Crysta',
            'Scorpio',
            'Venue',
            'Nexon',
            'Figo',
            'Wagon R',
            'Elantra',
            'X1',
            'Q3',
            'C-Class',
            'Rapid',
            'Vento',
            'Kicks',
          ][index % 30],
      modelVariation:
          [
            'Sportz',
            'Sportz',
            'XT',
            'VDi',
            'Hybrid',
            'Sport',
            'Premium',
            'Titanium',
            'W8',
            'GT',
            'VTi',
            'Delta',
            'SX',
            'XZ+',
            'HTK+',
            'VXI',
            'VX',
            'GX',
            'S11',
            'SX',
            'XZ+',
            'Titanium',
            'VXI',
            'SX',
            'sDrive20d',
            'Premium Plus',
            'Progressive',
            'Monte Carlo',
            'Highline',
            'XV',
          ][index % 30],
      description: 'Well maintained car in excellent condition',
      price:
          '${[430000, 210000, 390000, 520000, 1200000, 1800000, 2200000, 680000, 950000, 750000, 890000, 650000, 1150000, 1400000, 1300000, 280000, 720000, 1650000, 1100000, 850000, 980000, 480000, 350000, 1580000, 2400000, 2800000, 3200000, 780000, 920000, 1020000][index % 30]}',
      auctionPriceIntervel: '5000',
      auctionStartingPrice:
          '${[380000, 180000, 340000, 470000, 1100000, 1650000, 2000000, 620000, 850000, 680000, 800000, 580000, 1000000, 1250000, 1150000, 250000, 650000, 1500000, 980000, 750000, 880000, 420000, 300000, 1400000, 2200000, 2500000, 2900000, 700000, 820000, 920000][index % 30]}',
      attributeId: ['attr1', 'attr2'],
      attributeVariationsId: ['var1', 'var2'],
      filters: {
        'year':
            '${[2019, 2011, 2018, 2017, 2020, 2016, 2021, 2015, 2019, 2018, 2020, 2019, 2021, 2020, 2022, 2013, 2019, 2021, 2018, 2020, 2022, 2016, 2014, 2021, 2017, 2019, 2020, 2018, 2019, 2021][index % 30]}',
        'km':
            '${[67000, 87000, 45000, 32000, 25000, 85000, 15000, 95000, 42000, 58000, 28000, 72000, 35000, 48000, 22000, 105000, 38000, 18000, 65000, 29000, 41000, 78000, 92000, 33000, 55000, 47000, 26000, 63000, 51000, 36000][index % 30]}',
        'fuel':
            [
              'Petrol',
              'Petrol',
              'Petrol',
              'Diesel',
              'Hybrid',
              'Diesel',
              'Petrol',
              'Diesel',
              'Diesel',
              'Petrol',
              'Petrol',
              'Petrol',
              'Diesel',
              'Diesel',
              'Petrol',
              'Petrol',
              'Petrol',
              'Diesel',
              'Diesel',
              'Petrol',
              'Diesel',
              'Petrol',
              'Petrol',
              'Petrol',
              'Diesel',
              'Petrol',
              'Petrol',
              'Petrol',
              'Diesel',
              'Petrol',
            ][index % 30],
        'transmission':
            [
              'Automatic',
              'Automatic',
              'Manual',
              'Manual',
              'Automatic',
              'Manual',
              'Automatic',
              'Manual',
              'Automatic',
              'Manual',
              'Manual',
              'CVT',
              'Automatic',
              'Manual',
              'Manual',
              'Manual',
              'Manual',
              'Automatic',
              'Manual',
              'Automatic',
              'Manual',
              'Manual',
              'Manual',
              'Automatic',
              'Automatic',
              'Automatic',
              'Automatic',
              'Manual',
              'Automatic',
              'CVT',
            ][index % 30],
        'owners':
            '${[3, 4, 2, 1, 1, 2, 1, 3, 2, 1, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1, 1, 3, 4, 1, 2, 1, 1, 2, 1, 2][index % 30]}',
        'engine':
            [
              '1.2L',
              '1.2L',
              '1.2L',
              '1.3L',
              '2.5L',
              '2.0L',
              '2.0L',
              '1.5L',
              '2.2L',
              '1.0L',
              '1.5L',
              '1.2L',
              '1.6L',
              '2.0L',
              '1.5L',
              '1.0L',
              '1.2L',
              '2.4L',
              '2.2L',
              '1.0L',
              '1.2L',
              '1.2L',
              '1.0L',
              '1.8L',
              '2.0L',
              '2.0L',
              '1.5L',
              '1.6L',
              '1.6L',
              '1.5L',
            ][index % 30],
        'condition':
            [
              'Excellent',
              'Good',
              'Good',
              'Excellent',
              'Excellent',
              'Fair',
              'Excellent',
              'Good',
              'Good',
              'Excellent',
              'Excellent',
              'Good',
              'Excellent',
              'Good',
              'Excellent',
              'Good',
              'Excellent',
              'Excellent',
              'Good',
              'Excellent',
              'Good',
              'Fair',
              'Good',
              'Excellent',
              'Good',
              'Excellent',
              'Excellent',
              'Good',
              'Excellent',
              'Good',
            ][index % 30],
      },
      latitude: '19.0760',
      longitude: '72.8777',
      userZoneId: 'zone_${index % 3 + 1}',
      parentZoneId: 'parent_zone_1',
      zoneId: 'zone_${index % 3 + 1}',
      landMark:
          [
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
            'Ernakulam',
            'Kollam',
            'Kottayam',
            'Thrissur',
            'Kozhikode',
            'Ernakulam',
            'Thiruvananthapuram',
            'Palakkad',
            'Alappuzha',
            'Kannur',
            'Ernakulam',
            'Kottayam',
            'Thiruvananthapuram',
            'Thrissur',
            'Kozhikode',
            'Kollam',
          ][index % 30],
      // More auction products - every 2nd product is auction instead of every 3rd
      ifAuction: index % 2 == 0 ? '1' : '0',
      auctionStatus: index % 2 == 0 ? 'active' : 'inactive',
      auctionStartin:
          DateTime.now().add(Duration(hours: index % 24)).toIso8601String(),
      auctionEndin:
          DateTime.now().add(Duration(days: (index % 7) + 1)).toIso8601String(),
      // Varied auction attempts: 0, 1, 2, or 3
      auctionAttempt:
          '${[0, 1, 2, 3, 0, 1, 0, 2, 1, 0, 3, 1, 0, 2, 1, 0, 1, 2, 0, 1, 0, 3, 2, 0, 1, 0, 2, 1, 0, 3][index % 30]}',
      adminApproval: '1',
      ifFinance: index % 2 == 0 ? '1' : '0',
      ifExchange: index % 3 == 0 ? '1' : '0',
      feature: index % 5 == 0 ? '1' : '0',
      status: '1',
      visiterCount: '${(index + 1) * 10}',
      ifSold: '0',
      ifExpired: '0',
      byDealer: ['0', '1', '1', '0', '1', '0', '1', '0', '1', '0'][index % 10],
      createdBy: 'user_${index + 1}',
      createdOn:
          DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      updatedOn:
          DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
    ),
  );

  final List<String> _brands = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Honda',
    'Toyota',
    'Mahindra',
    'BMW',
    'Audi',
    'Ford',
    'Volkswagen',
    'Kia',
    'Skoda',
    'Nissan',
    'Renault',
    'Mercedes',
  ];

  final List<String> _priceRanges = [
    'all',
    'Under ₹2 Lakh',
    '₹2-5 Lakh',
    '₹5-10 Lakh',
    '₹10-20 Lakh',
    'Above ₹20 Lakh',
  ];

  final List<String> _yearRanges = [
    'all',
    '2020 & Above',
    '2018-2019',
    '2015-2017',
    '2010-2014',
    'Below 2010',
  ];

  final List<String> _ownerRanges = [
    'all',
    '1st Owner',
    '2nd Owner',
    '3rd Owner',
    '4+ Owners',
  ];

  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid',
  ];

  final List<String> _transmissions = ['Manual', 'Automatic', 'CVT'];

  final List<String> _kmRanges = [
    'all',
    'Under 10K',
    '10K-30K',
    '30K-50K',
    '50K-80K',
    'Above 80K',
  ];

  final List<String> _soldByOptions = [
    'all',
    'Dealer',
    'Owner',
    'Certified Dealer',
  ];

  final List<String> _keralaCities = [
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

  final List<String> _listingTypes = ['sale', 'auction'];

  List<Product> get filteredProducts {
    List<Product> filtered = _products;

    // Enhanced search functionality
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered =
          filtered.where((product) {
            final searchableText = [
              product.title.toLowerCase(),
              product.brand.toLowerCase(),
              product.model.toLowerCase(),
              product.modelVariation.toLowerCase(),
              product.landMark.toLowerCase(),
              product.filters['fuel']?.toLowerCase() ?? '',
              product.filters['transmission']?.toLowerCase() ?? '',
              product.filters['year']?.toString() ?? '',
              product.byDealer == '1' ? 'dealer' : 'owner',
            ].join(' ');

            return searchableText.contains(query);
          }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered =
          filtered
              .where((product) => product.landMark == _selectedLocation)
              .toList();
    }

    if (_listingType == 'auction') {
      filtered = filtered.where((product) => product.ifAuction == '1').toList();
    } else if (_listingType == 'sale') {
      filtered = filtered.where((product) => product.ifAuction == '0').toList();
    }

    // Brand filter
    if (_selectedBrands.isNotEmpty) {
      filtered =
          filtered
              .where((product) => _selectedBrands.contains(product.brand))
              .toList();
    }

    // Price filter (works for both sale and auction)
    if (_selectedPriceRange != 'all') {
      filtered =
          filtered.where((product) {
            // Use auction starting price for auctions, regular price for sales
            int price =
                product.ifAuction == '1'
                    ? (int.tryParse(product.auctionStartingPrice) ?? 0)
                    : (int.tryParse(product.price) ?? 0);

            switch (_selectedPriceRange) {
              case 'Under ₹2 Lakh':
                return price < 200000;
              case '₹2-5 Lakh':
                return price >= 200000 && price < 500000;
              case '₹5-10 Lakh':
                return price >= 500000 && price < 1000000;
              case '₹10-20 Lakh':
                return price >= 1000000 && price < 2000000;
              case 'Above ₹20 Lakh':
                return price >= 2000000;
              default:
                return true;
            }
          }).toList();
    }

    // Year filter
    if (_selectedYearRange != 'all') {
      filtered =
          filtered.where((product) {
            int year =
                int.tryParse(product.filters['year']?.toString() ?? '0') ?? 0;
            switch (_selectedYearRange) {
              case '2020 & Above':
                return year >= 2020;
              case '2018-2019':
                return year >= 2018 && year <= 2019;
              case '2015-2017':
                return year >= 2015 && year <= 2017;
              case '2010-2014':
                return year >= 2010 && year <= 2014;
              case 'Below 2010':
                return year < 2010;
              default:
                return true;
            }
          }).toList();
    }

    // Owners filter
    if (_selectedOwnersRange != 'all') {
      filtered =
          filtered.where((product) {
            int owners =
                int.tryParse(product.filters['owners']?.toString() ?? '0') ?? 0;
            switch (_selectedOwnersRange) {
              case '1st Owner':
                return owners == 1;
              case '2nd Owner':
                return owners == 2;
              case '3rd Owner':
                return owners == 3;
              case '4+ Owners':
                return owners >= 4;
              default:
                return true;
            }
          }).toList();
    }

    // Fuel type filter
    if (_selectedFuelTypes.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => _selectedFuelTypes.contains(
                  product.filters['fuel']?.toString() ?? '',
                ),
              )
              .toList();
    }

    // Transmission filter
    if (_selectedTransmissions.isNotEmpty) {
      filtered =
          filtered
              .where(
                (product) => _selectedTransmissions.contains(
                  product.filters['transmission']?.toString() ?? '',
                ),
              )
              .toList();
    }

    // KM filter
    if (_selectedKmRange != 'all') {
      filtered =
          filtered.where((product) {
            int km =
                int.tryParse(product.filters['km']?.toString() ?? '0') ?? 0;
            switch (_selectedKmRange) {
              case 'Under 10K':
                return km < 10000;
              case '10K-30K':
                return km >= 10000 && km < 30000;
              case '30K-50K':
                return km >= 30000 && km < 50000;
              case '50K-80K':
                return km >= 50000 && km < 80000;
              case 'Above 80K':
                return km >= 80000;
              default:
                return true;
            }
          }).toList();
    }

    // Sold by filter
    if (_selectedSoldBy != 'all') {
      filtered =
          filtered.where((product) {
            switch (_selectedSoldBy) {
              case 'Owner':
                return product.byDealer == '0';
              case 'Dealer':
              case 'Certified Dealer':
                return product.byDealer == '1';
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
                              'Filter Cars',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedBrands.clear();
                                  _selectedPriceRange = 'all';
                                  _selectedYearRange = 'all';
                                  _selectedOwnersRange = 'all';
                                  _selectedFuelTypes.clear();
                                  _selectedTransmissions.clear();
                                  _selectedKmRange = 'all';
                                  _selectedSoldBy = 'all';
                                });
                              },
                              child: Text(
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
                                'Brand',
                                _brands,
                                _selectedBrands,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'Price Range',
                                _priceRanges,
                                _selectedPriceRange,
                                (value) => setModalState(
                                  () => _selectedPriceRange = value,
                                ),
                                subtitle:
                                    _listingType == 'auction'
                                        ? 'Filter by starting bid price'
                                        : 'Filter by sale price',
                              ),
                              _buildSingleSelectFilterSection(
                                'Year',
                                _yearRanges,
                                _selectedYearRange,
                                (value) => setModalState(
                                  () => _selectedYearRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Number of Owners',
                                _ownerRanges,
                                _selectedOwnersRange,
                                (value) => setModalState(
                                  () => _selectedOwnersRange = value,
                                ),
                              ),
                              _buildMultiSelectFilterSection(
                                'Fuel Type',
                                _fuelTypes,
                                _selectedFuelTypes,
                                setModalState,
                              ),
                              _buildMultiSelectFilterSection(
                                'Transmission',
                                _transmissions,
                                _selectedTransmissions,
                                setModalState,
                              ),
                              _buildSingleSelectFilterSection(
                                'KM Driven',
                                _kmRanges,
                                _selectedKmRange,
                                (value) => setModalState(
                                  () => _selectedKmRange = value,
                                ),
                              ),
                              _buildSingleSelectFilterSection(
                                'Sold By',
                                _soldByOptions,
                                _selectedSoldBy,
                                (value) => setModalState(
                                  () => _selectedSoldBy = value,
                                ),
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
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  ); // Just close the dialog/screen
                                },
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
                            const SizedBox(width: 12), // Space between buttons
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
                                child: Text(
                                  'Apply Filters',
                                  style: const TextStyle(
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
    ValueChanged<String> onChanged, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
    if (_selectedBrands.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedYearRange != 'all') count++;
    if (_selectedOwnersRange != 'all') count++;
    if (_selectedFuelTypes.isNotEmpty) count++;
    if (_selectedTransmissions.isNotEmpty) count++;
    if (_selectedKmRange != 'all') count++;
    if (_selectedSoldBy != 'all') count++;
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
              return _keralaCities.map((String city) {
                return PopupMenuItem<String>(
                  value: city,
                  child: Row(
                    children: [
                      if (_selectedLocation == city)
                        const Icon(Icons.check, color: Colors.blue, size: 16),
                      if (_selectedLocation == city) const SizedBox(width: 8),
                      Text(city == 'all' ? 'All Kerala' : city),
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
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by brand, model, location, fuel type...',
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
            ),
          ),

          // Market Place / Auction Toggle
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _listingType = 'sale';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _listingType == 'sale'
                                  ? Palette.primaryblue
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow:
                              _listingType == 'sale'
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Text(
                          'Market Place',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight:
                                _listingType == 'sale'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                _listingType == 'sale'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _listingType = 'auction';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _listingType == 'auction'
                                  ? Palette.primaryblue
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow:
                              _listingType == 'auction'
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Text(
                          'Auction',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight:
                                _listingType == 'auction'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                _listingType == 'auction'
                                    ? Colors.white
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products List
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final products = filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No cars found',
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
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isAuction = product.ifAuction == '1';
    final isFinanceAvailable = product.ifFinance == '1';
    final isExchangeAvailable = product.ifExchange == '1';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30), // darker shadow
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
              // Car Image
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.asset(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.directions_car,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Car Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Model Variation
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.modelVariation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Price with range
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAuction
                                ? '₹${_formatNumber(int.tryParse(product.auctionStartingPrice) ?? 0)} - ₹${_formatPriceWithLakh(int.tryParse(product.price) ?? 0)}'
                                : '₹ ${_formatPriceWithLakh(int.tryParse(product.price) ?? 0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Palette.primaryblue,
                            ),
                          ),
                        ],
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
                            product.landMark,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Car Details Row (Year, Owner, KM, Fuel, Transmission)
                      Row(
                        children: [
                          _buildDetailChip(
                            Icon(
                              Icons.calendar_today,
                              size: 10,
                              color: Colors.grey[700],
                            ),
                            '${product.filters['year']}',
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.person,
                              size: 10,
                              color: Colors.grey[700],
                            ),
                            _getOwnerText(product.filters['owners'] ?? '1'),
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.speed,
                              size: 10,
                              color: Colors.grey[700],
                            ),
                            '${_formatNumber(int.tryParse(product.filters['km']?.toString() ?? '0') ?? 0)} KM',
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          _buildDetailChip(
                            Icon(
                              Icons.local_gas_station,
                              size: 10,
                              color: Colors.grey[700],
                            ),
                            '${product.filters['fuel']}',
                          ),
                          const SizedBox(width: 4),
                          _buildDetailChip(
                            Icon(
                              Icons.settings,
                              size: 10,
                              color: Colors.grey[700],
                            ),
                            '${product.filters['transmission']}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom section with finance/exchange or auction info
          if (isAuction || isFinanceAvailable || isExchangeAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color:
                    isAuction ? Palette.primarylightblue : Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child:
                  isAuction
                      ? _buildAuctionInfo(product)
                      : _buildFinanceExchangeInfo(
                        isFinanceAvailable,
                        isExchangeAvailable,
                      ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuctionInfo(Product product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              'Attempts: ${product.auctionAttempt}/3',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: Text(
            'AUCTION',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceExchangeInfo(
    bool isFinanceAvailable,
    bool isExchangeAvailable,
  ) {
    if (!isFinanceAvailable && !isExchangeAvailable) {
      return const SizedBox.shrink();
    }

    // If both are available, show them side by side with full width
    if (isFinanceAvailable && isExchangeAvailable) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.primarylightblue,
                borderRadius: BorderRadius.circular(8),
                // border: Border.all(color: Palette.primarylightblue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Finance Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.primarylightblue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Palette.primarylightblue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Exchange Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // If only one is available, show it full width
    if (isFinanceAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Palette.primarylightblue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.primarylightblue),
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
      );
    }

    if (isExchangeAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Palette.primarylightblue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 16, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              'Exchange Available',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailChip(Widget icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
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

  String _getOwnerText(String owners) {
    switch (owners) {
      case '1':
        return '1st Owner';
      case '2':
        return '2nd Owner';
      case '3':
        return '3rd Owner';
      default:
        return '${owners}th Owner';
    }
  }

  String _formatPriceWithLakh(int price) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
