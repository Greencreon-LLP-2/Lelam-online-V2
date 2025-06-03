// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class JunkWidget extends StatefulWidget {
  const JunkWidget({super.key});

  @override
  State<JunkWidget> createState() => _JunkWidgetState();
}

class _JunkWidgetState extends State<JunkWidget> {
  final List<String> statuses = [
    'Reschedule Request',
    'Expired',
    'Skipped',
    'Attempts over',
    'Inactive',
    'cancelled',
    'Sold out',
  ];

  int selectedIndex = 0;

  Widget _getStatusWidget(int index) {
    switch (index) {
      case 0:
        return const Text('Reschedule Requests go here.');
      case 1:
        return const Text('Expired details go here.');
      case 2:
        return const Text('Skipped details go here.');
      case 3:
        return const Text('Attempts over details go here.');
      case 4:
        return const Text('Inactive details go here.');
      case 5:
        return const Text('Cancelled details go here.');
      case 6:
        return const Text('Sold out details go here.');

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(statuses.length * 2 - 1, (i) {
              if (i.isEven) {
                final index = i ~/ 2;
                return StatusPill(
                  label: statuses[index],
                  isActive: index <= selectedIndex,
                  activeColor: Colors.green,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              } else {
                final leftIndex = (i - 1) ~/ 2;
                final isActive = leftIndex < selectedIndex;
                return PillConnector(
                  isActive: isActive,
                  activeColor: Colors.green,
                  inactiveColor: Colors.grey,
                );
              }
            }),
          ),
        ),
        const SizedBox(height: 24),
        _getStatusWidget(selectedIndex),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  const StatusPill({
    super.key,
    required this.label,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? activeColor : inactiveColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class PillConnector extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const PillConnector({
    super.key,
    this.isActive = false,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
