import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoDetailPage extends StatelessWidget {
  final String title;
  const InfoDetailPage({super.key, required this.title});

  static const Map<String, String> _content = {
    'EULA':
        'End-User License Agreement\n\nThis is a sample EULA text for demonstration purposes.\n\nBy using this app you agree to the terms laid out here. Please read carefully.',
    'Privacy Policy':
        'Privacy Policy\n\nWe respect your privacy. This is a placeholder privacy policy. We collect minimal data for app functionality.',
    'Terms of Service':
        'Terms of Service\n\nThese are the sample terms of service. Users must comply with the community rules and guidelines.',
    'About Us':
        'About Us\n\nLelam is a demo bidding and ads platform. This text is hardcoded for now. Our mission is to connect buyers and sellers locally.',
    'Shipping Policy':
        'Shipping Policy\n\nSample shipping policy details go here. Shipping times depend on the vendor and chosen service.',
  };

  @override
  Widget build(BuildContext context) {
    final content = _content[title] ?? 'No content available.';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 1,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          content,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
