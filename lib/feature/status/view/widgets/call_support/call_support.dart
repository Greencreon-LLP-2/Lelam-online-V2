import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallSupportButton extends StatelessWidget {
  final String label;
  final String phoneNumber;
  final VoidCallback? onPressed;

  const CallSupportButton({
    super.key,
    this.label = 'Call Support',
    this.phoneNumber = '+919876543210', // Default phone number
    this.onPressed,
  });

  Future<void> _makePhoneCall(BuildContext context) async {
    // Ensure phoneNumber is cleaned (remove spaces, dashes, etc.)
    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[\s()-]'), '');
    final Uri telUri = Uri(
      scheme: 'tel',
      path: cleanPhoneNumber,
    );
    debugPrint('Attempting to call: $telUri');

    try {
      bool canLaunch = await canLaunchUrl(telUri);
      debugPrint('Can launch tel URL: $canLaunch');
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open phone dialer. Please check device capabilities.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      await launchUrl(telUri);
      debugPrint('Successfully launched dialer with: $telUri');
    } catch (e) {
      debugPrint('Error launching dialer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching dialer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () => _makePhoneCall(context),
      icon: const Icon(Icons.phone),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        elevation: 0,
      ),
    );
  }
}