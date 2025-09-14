import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFAQs();
  }

  Future<void> fetchFAQs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await apiService.get(url: faqUrl);
      print(data);
      // Convert Map values to List if needed
      final List<Map<String, dynamic>> faqList = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          faqList.add(item);
        }
      }

      setState(() {
        faqs = faqList;
      });
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      setState(() {
        faqs = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('FAQ', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchFAQs,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : faqs.isEmpty
                ? Center(
                  child: Column(
                    children: [
                      Text('No FAQs available'),
                      IconButton(
                        onPressed: () async {
                          await fetchFAQs();
                        },
                        icon: Icon(Icons.refresh),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    return _buildFAQItem(faqs[index]);
                  },
                ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    final question = faq['qus'] ?? 'No Question';
    final answer = faq['ans'] ?? 'No Answer';
    final pdf = faq['pdf'];
    final orderNo = faq['order_no'] ?? 0;
    final status = faq['status'] == 1 ? 'Active' : 'Inactive';

    // Format dates
    DateTime? createdOn;

    try {
      createdOn = DateTime.parse(faq['created_on'] ?? '');
    } catch (_) {}

    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Order: $orderNo • Status: $status'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
          if (pdf != null && pdf.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature is coming soon')),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'View Attachment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (createdOn != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ' ${createdOn != null ? dateFormat.format(createdOn) : '-'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
