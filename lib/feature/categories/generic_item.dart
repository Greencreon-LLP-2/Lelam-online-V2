import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class GenericItem {
  final String id;
  final String name;
  final String type;
  final String year;
  final String km;
  final String price;
  final String location;
  final String brand;
  final String fuel;
  final String condition;
  final String image;
  final String verified;
  final String featured;
  final String description;
  final String owner;
  final String transmission;
  final String ifFinance;
  final String? categoryId; // Optional for category filtering

  GenericItem({
    required this.id,
    required this.name,
    required this.type,
    required this.year,
    required this.km,
    required this.price,
    required this.location,
    required this.brand,
    required this.fuel,
    required this.condition,
    required this.image,
    required this.verified,
    required this.featured,
    required this.description,
    required this.owner,
    required this.transmission,
    required this.ifFinance,
    this.categoryId,
  });
}

class GenericListingPage<T extends GenericItem> extends StatefulWidget {
  final String pageTitle;
  final String searchHint;
  final List<T> items;
  final List<String> itemTypes;
  final List<String> priceRanges;
  final List<String> locations;
  final List<String> conditions;
  final List<String> fuelTypes;
  final String detailsRouteName;
  final IconData imageErrorIcon;
  final String? categoryId; // For filtering by category ID
  final bool showKm; // Whether to show km field
  final bool showTransmission; // Whether to show transmission field
  final String itemTypeLabel; // Label for item type (e.g., "Property Type", "Car Type")

  const GenericListingPage({
    super.key,
    required this.pageTitle,
    required this.searchHint,
    required this.items,
    required this.itemTypes,
    required this.priceRanges,
    required this.locations,
    required this.conditions,
    required this.fuelTypes,
    required this.detailsRouteName,
    required this.imageErrorIcon,
    this.categoryId,
    this.showKm = true,
    this.showTransmission = true,
    required this.itemTypeLabel,
  });

  @override
  State<GenericListingPage<T>> createState() => _GenericListingPageState<T>();
}

class _GenericListingPageState<T extends GenericItem> extends State<GenericListingPage<T>> {
  String _searchQuery = '';
  String _selectedLocation = 'all';
  List<String> _selectedItemTypes = [];
  String _selectedPriceRange = 'all';
  String _selectedCondition = 'all';
  List<String> _selectedFuelTypes = [];

  final TextEditingController _searchController = TextEditingController();
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

  List<T> get filteredItems {
    List<T> filtered = widget.items;

    if (widget.categoryId != null) {
      filtered = filtered.where((item) => item.categoryId == widget.categoryId).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.brand.toLowerCase().contains(query) ||
            item.type.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedLocation != 'all') {
      filtered = filtered.where((item) => item.location == _selectedLocation).toList();
    }

    if (_selectedItemTypes.isNotEmpty) {
      filtered = filtered.where((item) => _selectedItemTypes.contains(item.type)).toList();
    }

    if (_selectedPriceRange != 'all') {
      filtered = filtered.where((item) {
        final price = int.tryParse(item.price) ?? 0;
        switch (_selectedPriceRange) {
          case 'Under 50K':
            return price < 50000;
          case '50K-1L':
            return price >= 50000 && price < 100000;
          case '1L-2L':
            return price >= 100000 && price < 200000;
          case '2L-5L':
            return price >= 200000 && price < 500000;
          case 'Above 5L':
            return price >= 500000;
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

    if (_selectedCondition != 'all') {
      filtered = filtered.where((item) => item.condition == _selectedCondition).toList();
    }

    if (_selectedFuelTypes.isNotEmpty) {
      filtered = filtered.where((item) => _selectedFuelTypes.contains(item.fuel)).toList();
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    Text(
                      'Filter ${widget.pageTitle}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedItemTypes.clear();
                          _selectedPriceRange = 'all';
                          _selectedCondition = 'all';
                          _selectedFuelTypes.clear();
                        });
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
                        widget.itemTypeLabel,
                        widget.itemTypes,
                        _selectedItemTypes,
                        setModalState,
                      ),
                      _buildSingleSelectFilterSection(
                        'Price Range',
                        widget.priceRanges,
                        _selectedPriceRange,
                        (value) => setModalState(() => _selectedPriceRange = value),
                      ),
                      _buildSingleSelectFilterSection(
                        'Condition',
                        widget.conditions,
                        _selectedCondition,
                        (value) => setModalState(() => _selectedCondition = value),
                      ),
                      _buildMultiSelectFilterSection(
                        'Fuel Type',
                        widget.fuelTypes,
                        _selectedFuelTypes,
                        setModalState,
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
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.primarypink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
          children: options.map((option) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Palette.primarypink : Colors.grey.shade300),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          children: options.map((option) {
            final isSelected = selectedValue == option;
            final displayText = option == 'all' ? 'Any $title' : option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Palette.primarypink : Colors.grey.shade300),
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    if (_selectedItemTypes.isNotEmpty) count++;
    if (_selectedPriceRange != 'all') count++;
    if (_selectedCondition != 'all') count++;
    if (_selectedFuelTypes.isNotEmpty) count++;
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
          hintText: widget.searchHint,
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by ${widget.pageTitle.toLowerCase()} type, brand, location...',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              return widget.locations.map((String location) {
                return PopupMenuItem<String>(
                  value: location,
                  child: Row(
                    children: [
                      if (_selectedLocation == location)
                        const Icon(Icons.check, color: Colors.blue, size: 16),
                      if (_selectedLocation == location) const SizedBox(width: 8),
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
                for (var item in filteredItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildItemCard(item),
                  ),
                if (filteredItems.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No ${widget.pageTitle.toLowerCase()} found',
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

  Widget _buildItemCard(T item) {
    final isFinanceAvailable = item.ifFinance == '1';
    final isFeatured = item.featured == '1';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
           // context.pushNamed(widget.detailsRouteName, params: {'id': item.id});
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
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(0)),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      widget.imageErrorIcon,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            if (item.verified == '1')
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
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.type,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹ ${formatPriceInt(double.tryParse(item.price) ?? 0)}',
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
                                  item.location,
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
                                    Icons.calendar_today,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  item.year,
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.construction,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  item.condition,
                                ),
                                const SizedBox(width: 4),
                                _buildDetailChip(
                                  Icon(
                                    Icons.local_gas_station,
                                    size: 8,
                                    color: Colors.grey[700],
                                  ),
                                  item.fuel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (widget.showKm && item.km != '0')
                                  _buildDetailChip(
                                    Icon(
                                      Icons.speed,
                                      size: 8,
                                      color: Colors.grey[700],
                                    ),
                                    '${_formatNumber(int.tryParse(item.km) ?? 0)} km',
                                  ),
                                if (widget.showKm && item.km != '0') const SizedBox(width: 4),
                                if (widget.showTransmission)
                                  _buildDetailChip(
                                    Icon(
                                      Icons.person,
                                      size: 8,
                                      color: Colors.grey[700],
                                    ),
                                    item.owner,
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
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                        Icon(Icons.account_balance, size: 10, color: Colors.white),
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