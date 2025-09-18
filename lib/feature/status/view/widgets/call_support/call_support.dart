import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallSupportButton extends StatelessWidget {
  
  final String label;


  const CallSupportButton({
    super.key,
   
    this.label = 'Call Support',

  });

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri telUri = Uri(scheme: 'tel', );
    try {
      if (!await canLaunchUrl(telUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open dialer'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      await launchUrl(telUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _makePhoneCall(context),
      icon: const Icon(Icons.phone),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:Colors.green,
        foregroundColor:  Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
       padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 2),
      elevation: 0,
      ),
    );
  }
}