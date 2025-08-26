// marketplace_components.dart
import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/utils/palette.dart';

// Common filter types
enum FilterType { multiSelect, singleSelect }

// Common filter section widget
Widget buildFilterSection({
  required String title,
  required List<String> options,
  required dynamic selectedValues,
  required FilterType filterType,
  required Function(dynamic) onChanged,
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
          final bool isSelected = filterType == FilterType.multiSelect
              ? (selectedValues as List<String>).contains(option)
              : selectedValues == option;

          final displayText = option == 'all' ? 'Any $title' : option;
          
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// Common filter bottom sheet
void showFilterBottomSheet({
  required BuildContext context,
  required List<Widget> filterSections,
  required VoidCallback onClearAll,
  required VoidCallback onApply,
}) {
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
                  const Text(
                    'Filter',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: onClearAll,
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
                    ...filterSections,
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
                        onApply();
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
      ),
    ),
  );
}

// Common search field
Widget buildSearchField({
  required TextEditingController controller,
  required String hintText,
  required ValueChanged<String> onChanged,
  String searchQuery = '',
}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
      suffixIcon: searchQuery.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade400),
              onPressed: () {
                controller.clear();
                onChanged('');
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

// Common app bar search field
Widget buildAppBarSearchField({
  required TextEditingController controller,
  required String hintText,
  required ValueChanged<String> onChanged,
  String searchQuery = '',
}) {
  return Container(
    height: 40,
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: controller,
      autofocus: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade400),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(top: 10),
      ),
      onChanged: onChanged,
    ),
  );
}

// Common detail chip
Widget buildDetailChip(Widget icon, String label) {
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

// Common price formatter
String formatPrice(int price) {
  if (price >= 10000000) {
    double crore = price / 10000000;
    return '${crore.toStringAsFixed(crore == crore.roundToDouble() ? 0 : 2)} Crore';
  } else if (price >= 100000) {
    double lakh = price / 100000;
    return '${lakh.toStringAsFixed(lakh == lakh.roundToDouble() ? 0 : 2)} Lakh';
  } else if (price >= 1000) {
    double thousand = price / 1000;
    return '${thousand.toStringAsFixed(thousand == thousand.roundToDouble() ? 0 : 1)}K';
  } else {
    return price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2);
  }
}

// Common number formatter
String formatNumber(num number) {
  if (number >= 100000) {
    return '${(number / 100000).toStringAsFixed(2)}L';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toStringAsFixed(number == number.roundToDouble() ? 0 : 2);
  }
}

// Common empty state widget
Widget buildEmptyState(String message, {String? subMessage}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ],
    ),
  );
}

// Common error state widget
Widget buildErrorState(String errorMessage, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          'Error: $errorMessage',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

// Common loading state
Widget buildLoadingState() {
  return const Center(child: CircularProgressIndicator());
}

// Common location dropdown
PopupMenuButton<String> buildLocationDropdown({
  required List<String> locations,
  required String selectedLocation,
  required ValueChanged<String> onLocationChanged,
}) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.location_on, color: Colors.black87),
    onSelected: onLocationChanged,
    itemBuilder: (BuildContext context) {
      return locations.map((String location) {
        return PopupMenuItem<String>(
          value: location,
          child: Row(
            children: [
              if (selectedLocation == location)
                const Icon(Icons.check, color: Colors.blue, size: 16),
              if (selectedLocation == location) const SizedBox(width: 8),
              Text(location == 'all' ? 'All Kerala' : location),
            ],
          ),
        );
      }).toList();
    },
  );
}

// Common filter button with badge
Widget buildFilterButtonWithBadge({
  required VoidCallback onPressed,
  required int activeFilterCount,
}) {
  return Stack(
    children: [
      IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.tune, color: Colors.black87),
      ),
      if (activeFilterCount > 0)
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
              '$activeFilterCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  );
}