import 'package:flutter/material.dart';
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
  late List<String> _selectedBrands;
  late String _selectedPriceRange;
  late String _selectedYearRange;
  late String _selectedOwnersRange;
  late List<String> _selectedFuelTypes;
  late List<String> _selectedTransmissions;
  late String _selectedKmRange;
  late String _selectedSoldBy;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                  ),
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
          children: options.map((option) {
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
                  color: isSelected ? Palette.primarypink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Palette.primarypink : Colors.grey.shade300,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(
                  widget.listingType == 'auction'
                      ? 'Filter Auction Items'
                      : 'Filter Items',
                  style: const TextStyle(
                    fontSize: 20,
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
                    'Brand',
                    widget.brands,
                    _selectedBrands,
                    setState,
                  ),
                  _buildSingleSelectFilterSection(
                    'Price Range',
                    widget.priceRanges,
                    _selectedPriceRange,
                    (value) => setState(() => _selectedPriceRange = value),
                    subtitle: widget.listingType == 'auction'
                        ? 'Filter by starting bid price'
                        : 'Filter by sale price',
                  ),
                  _buildSingleSelectFilterSection(
                    'Year',
                    widget.yearRanges,
                    _selectedYearRange,
                    (value) => setState(() => _selectedYearRange = value),
                  ),
                  _buildSingleSelectFilterSection(
                    'Number of Owners',
                    widget.ownerRanges,
                    _selectedOwnersRange,
                    (value) => setState(() => _selectedOwnersRange = value),
                  ),
                  _buildMultiSelectFilterSection(
                    'Fuel Type',
                    widget.fuelTypes,
                    _selectedFuelTypes,
                    setState,
                  ),
                  _buildMultiSelectFilterSection(
                    'Transmission',
                    widget.transmissions,
                    _selectedTransmissions,
                    setState,
                  ),
                  _buildSingleSelectFilterSection(
                    'KM Driven',
                    widget.kmRanges,
                    _selectedKmRange,
                    (value) => setState(() => _selectedKmRange = value),
                  ),
                  _buildSingleSelectFilterSection(
                    'Sold By',
                    widget.soldByOptions,
                    _selectedSoldBy,
                    (value) => setState(() => _selectedSoldBy = value),
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
                      backgroundColor: Palette.primaryblue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}