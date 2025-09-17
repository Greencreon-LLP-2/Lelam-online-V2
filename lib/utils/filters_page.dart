import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/utils/custom_safe_area.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

class FilterPage extends StatefulWidget {
  final List<String> brands;
  final List<String> priceRanges;
  final List<String> yearRanges;
  final List<String> ownerRanges;
  final List<String> fuelTypes;
  final List<String> transmissions;
  final List<String> kmRanges;
  final List<String> soldByOptions;
  final List<String> selectedBrands;
  final String selectedPriceRange;
  final String selectedYearRange;
  final String selectedOwnersRange;
  final List<String> selectedFuelTypes;
  final List<String> selectedTransmissions;
  final String selectedKmRange;
  final String selectedSoldBy;
  final String listingType;
  final Function({
    required List<String> selectedBrands,
    required String selectedPriceRange,
    required String selectedYearRange,
    required String selectedOwnersRange,
    required List<String> selectedFuelTypes,
    required List<String> selectedTransmissions,
    required String selectedKmRange,
    required String selectedSoldBy,
  }) onApplyFilters;

  const FilterPage({
    super.key,
    required this.brands,
    required this.priceRanges,
    required this.yearRanges,
    required this.ownerRanges,
    required this.fuelTypes,
    required this.transmissions,
    required this.kmRanges,
    required this.soldByOptions,
    required this.selectedBrands,
    required this.selectedPriceRange,
    required this.selectedYearRange,
    required this.selectedOwnersRange,
    required this.selectedFuelTypes,
    required this.selectedTransmissions,
    required this.selectedKmRange,
    required this.selectedSoldBy,
    required this.listingType,
    required this.onApplyFilters,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  static const Color primaryblue = Color(0xFF2d5ba9);
  late List<String> _selectedBrands;
  late String _selectedPriceRange;
  late String _selectedYearRange;
  late String _selectedOwnersRange;
  late List<String> _selectedFuelTypes;
  late List<String> _selectedTransmissions;
  late String _selectedKmRange;
  late String _selectedSoldBy;
  String _selectedCategory = 'Brand';
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBrands = List.from(widget.selectedBrands);
    _selectedPriceRange = widget.selectedPriceRange;
    _selectedYearRange = widget.selectedYearRange;
    _selectedOwnersRange = widget.selectedOwnersRange;
    _selectedFuelTypes = List.from(widget.selectedFuelTypes);
    _selectedTransmissions = List.from(widget.selectedTransmissions);
    _selectedKmRange = widget.selectedKmRange;
    _selectedSoldBy = widget.selectedSoldBy;

    // Initialize price text fields if selectedPriceRange is not 'all'
    if (_selectedPriceRange != 'all') {
      final parts = _selectedPriceRange.split('-');
      if (parts.length == 2) {
        _minPriceController.text = parts[0];
        _maxPriceController.text = parts[1];
      }
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Widget _buildMultiSelectFilterSection(
    String title,
    List<String> options,
    List<String> selectedValues,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select $title',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedValues.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedValues.remove(option);
                  } else {
                    selectedValues.add(option);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Palette.primarypink.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedValues.add(option);
                          } else {
                            selectedValues.remove(option);
                          }
                        });
                      },
                      activeColor: Palette.primarypink,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Palette.primarypink : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    if (title == 'Price Range') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select $title',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Palette.primarypink),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (value) {
                    setState(() {
                      final min = _minPriceController.text;
                      final max = _maxPriceController.text;
                      if (min.isNotEmpty && max.isNotEmpty) {
                        _selectedPriceRange = '$min-$max';
                      } else {
                        _selectedPriceRange = 'all';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Palette.primarypink),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (value) {
                    setState(() {
                      final min = _minPriceController.text;
                      final max = _maxPriceController.text;
                      if (min.isNotEmpty && max.isNotEmpty) {
                        _selectedPriceRange = '$min-$max';
                      } else {
                        _selectedPriceRange = 'all';
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPriceRange = 'all';
                _minPriceController.clear();
                _maxPriceController.clear();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedPriceRange == 'all' ? Palette.primarypink.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectedPriceRange == 'all' ? Palette.primarypink : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'all',
                    groupValue: _selectedPriceRange,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPriceRange = value;
                          _minPriceController.clear();
                          _maxPriceController.clear();
                        });
                      }
                    },
                    activeColor: Palette.primarypink,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Any Price Range',
                      style: TextStyle(
                        color: Palette.primarypink,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select $title',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedValue == option;
            final displayText = option == 'all' ? 'Any $title' : option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Palette.primarypink.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: option,
                      groupValue: selectedValue,
                      onChanged: (value) {
                        if (value != null) onChanged(value);
                      },
                      activeColor: Palette.primarypink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: isSelected ? Palette.primarypink : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    switch (_selectedCategory) {
      case 'Brand':
        return _buildMultiSelectFilterSection(
          'Brand',
          widget.brands,
          _selectedBrands,
        );
      case 'Price Range':
        return _buildSingleSelectFilterSection(
          'Price Range',
          widget.priceRanges,
          _selectedPriceRange,
          (value) => setState(() => _selectedPriceRange = value),
          subtitle: widget.listingType == 'auction'
              ? 'Filter by starting bid price'
              : 'Filter by sale price',
        );
      case 'Year':
        return _buildSingleSelectFilterSection(
          'Year',
          widget.yearRanges,
          _selectedYearRange,
          (value) => setState(() => _selectedYearRange = value),
        );
      case 'Number of Owners':
        return _buildSingleSelectFilterSection(
          'Number of Owners',
          widget.ownerRanges,
          _selectedOwnersRange,
          (value) => setState(() => _selectedOwnersRange = value),
        );
      case 'Fuel Type':
        return _buildMultiSelectFilterSection(
          'Fuel Type',
          widget.fuelTypes,
          _selectedFuelTypes,
        );
      case 'Transmission':
        return _buildMultiSelectFilterSection(
          'Transmission',
          widget.transmissions,
          _selectedTransmissions,
        );
      case 'KM Driven':
        return _buildSingleSelectFilterSection(
          'KM Driven',
          widget.kmRanges,
          _selectedKmRange,
          (value) => setState(() => _selectedKmRange = value),
        );
      case 'Sold By':
        return _buildSingleSelectFilterSection(
          'Sold By',
          widget.soldByOptions,
          _selectedSoldBy,
          (value) => setState(() => _selectedSoldBy = value),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Brand',
      'Price Range',
      'Year',
      'Number of Owners',
      'Fuel Type',
      'Transmission',
      'KM Driven',
      'Sold By',
    ];

    return CustomSafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Top handle and title
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.listingType == 'auction'
                        ? 'Filter Auction Items'
                        : 'Filter Items',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedBrands.clear();
                        _selectedPriceRange = 'all';
                        _selectedYearRange = 'all';
                        _selectedOwnersRange = 'all';
                        _selectedFuelTypes.clear();
                        _selectedTransmissions.clear();
                        _selectedKmRange = 'all';
                        _selectedSoldBy = 'all';
                        _minPriceController.clear();
                        _maxPriceController.clear();
                      });
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Two-column layout
            Expanded(
              child: Row(
                children: [
                  // Left: Category list
                  Container(
                    width: 100,
                    color: primaryblue,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? primaryblue : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? primaryblue : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Right: Options for selected category
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildOptionsSection(),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApplyFilters(
                          selectedBrands: _selectedBrands,
                          selectedPriceRange: _selectedPriceRange,
                          selectedYearRange: _selectedYearRange,
                          selectedOwnersRange: _selectedOwnersRange,
                          selectedFuelTypes: _selectedFuelTypes,
                          selectedTransmissions: _selectedTransmissions,
                          selectedKmRange: _selectedKmRange,
                          selectedSoldBy: _selectedSoldBy,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryblue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
    );
  }
}