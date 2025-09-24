import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:dio/dio.dart'; // For downloading PDF
import 'package:open_file/open_file.dart'; // For opening PDF
import 'package:path_provider/path_provider.dart'; // For temporary storage
import 'package:path/path.dart' as path; // For file extension handling
import 'dart:io';

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
        if (s.length == 10) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        if (value.isEmpty) return null;
        final iso = DateTime.tryParse(value);
        if (iso != null) return iso;
        final asInt = int.tryParse(value);
        if (asInt != null) {
          final s = value;
          if (s.length == 10) return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
          return DateTime.fromMillisecondsSinceEpoch(asInt);
        }
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

  Future<void> _openPDF(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available')),
      );
      return;
    }

    // Optional: Show a loading dialog for better UX during download
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Downloading PDF...'),
          ],
        ),
      ),
    );

    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      
      // Generate a safe filename: Use last part of URL, ensure .pdf extension
      String fileName = path.basename(pdfUrl);
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        // If no .pdf extension, append it (common for generic URLs)
        fileName = '$fileName.pdf';
      }
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);

      // Download the PDF
      await Dio().download(pdfUrl, filePath);

      // Close loading dialog
      Navigator.of(context).pop();

      // Open the downloaded PDF with explicit MIME type
      final result = await OpenFile.open(
        filePath,
        type: 'application/pdf',  // Explicit MIME type to force PDF viewer
      );
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${result.message}')),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('Error downloading or opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening PDF. Please check your connection.')),
      );
    }
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
                                      backgroundColor: Colors.red.shade500,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _openPDF(pdf),
                                    icon: const Icon(Icons.picture_as_pdf,color: Colors.white,),
                                    label: const Text('View PDF' , style: TextStyle(color: Colors.white),),
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
              }).toList(),
          ],
        ),
      ),
    );
  }
}