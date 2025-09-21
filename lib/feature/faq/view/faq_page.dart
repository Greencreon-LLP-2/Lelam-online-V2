// ...existing code...
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';

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
      final Map<String, dynamic> data = await apiService.get(url: faqUrl);

      // keep compatibility with different API formats ('true' string, boolean true, 1, '1')
      final statusRaw = data['status'];
      final bool success = statusRaw == true ||
          statusRaw == 'true' ||
          statusRaw == 1 ||
          statusRaw == '1' ||
          (statusRaw is String && statusRaw.toLowerCase() == 'success');

      if (success && data['data'] != null) {
        setState(() {
          faqs = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        setState(() {
          faqs = [];
        });
      }
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is int) {
        final s = value.toString();
        // seconds -> 10 digits, milliseconds -> 13 digits
        if (s.length == 10) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        if (value.isEmpty) return null;
        // try ISO
        final iso = DateTime.tryParse(value);
        if (iso != null) return iso;
        // numeric string?
        final asInt = int.tryParse(value);
        if (asInt != null) {
          final s = value;
          if (s.length == 10) return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
          return DateTime.fromMillisecondsSinceEpoch(asInt);
        }
        // try common formats (fallback)
        try {
          return DateFormat.yMd().parseLoose(value);
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  String _normalizeStatus(dynamic raw) {
    if (raw == null) return 'Inactive';
    if (raw == true || raw == 1 || raw == '1' || (raw is String && raw.toLowerCase() == 'true')) {
      return 'Active';
    }
    final s = raw.toString().toLowerCase();
    if (s.contains('act') || s.contains('enable')) return 'Active';
    return 'Inactive';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('FAQ', style: TextStyle(color: Colors.white)),
      ),
      // Always provide a scrollable to RefreshIndicator
      body: RefreshIndicator(
        onRefresh: fetchFAQs,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          children: [
            if (isLoading)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (faqs.isEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No FAQs available'),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () async => await fetchFAQs(),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...faqs.map((faq) {
                final question = faq['qus'] ?? 'No Question';
                final answer = faq['ans'] ?? 'No Answer';
                final pdf = faq['pdf'];
                final orderNo = faq['order_no'] ?? 0;
                final statusLabel = _normalizeStatus(faq['status']);
                final createdOn = _parseDate(faq['created_on']);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    collapsedBackgroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        orderNo.toString(),
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      question,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              answer,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (pdf != null && pdf.toString().isNotEmpty)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Feature is coming soon')),
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('View Attachment'),
                                  ),
                                const Spacer(),
                                Text(
                                  'Order #$orderNo',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
// ...existing code...