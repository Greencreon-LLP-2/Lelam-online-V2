import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('FAQ', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _buildFAQItem(
            '#1 What is lelamonline ?',
            'LelamOnline is an online platform for selling and buying usedcars and other items through meetings',
          ),
          _buildFAQItem(
            '#2 How to sell my item in Lelam ?',
            'Details about selling items...',
          ),
          _buildFAQItem(
            '#3 How to purchase from lelamOnline ?',
            'Details about purchasing...',
          ),
          _buildFAQItem(
            '#4 Will my contact number shared ?',
            'Information about contact sharing policy...',
          ),
          _buildFAQItem(
            '#5 How is auction working ?',
            'Details about auction process...',
          ),
          _buildFAQItem(
            '#6 Is there any charges ?',
            'Information about charges and fees...',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
