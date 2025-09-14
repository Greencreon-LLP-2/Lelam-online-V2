
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExpiredMeetingsPage extends StatefulWidget {
  final String? userId;

  const ExpiredMeetingsPage({super.key, required this.userId});

  @override
  _ExpiredMeetingsPageState createState() => _ExpiredMeetingsPageState();
}

class _ExpiredMeetingsPageState extends State<ExpiredMeetingsPage> {
  String token = "5cb2c9b569416b5db1604e0e12478ded";
  List<dynamic> meetings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('User ID: ${widget.userId}');
    _loadConfigAndFetchMeetings();
  }


  Future<void> _loadConfigAndFetchMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token') ?? token;
      isLoading = true;
    });

    if (token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token missing. Please log in again.'),
          ),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    await _fetchMeetings();
  }

  List<dynamic> _parseJsonSafely(String body) {
    String cleanBody = body
        .replaceAll(RegExp(r'<br\s*/?>', multiLine: true), '')
        .replaceAll(RegExp(r'<b>|</b>', multiLine: true), '')
        .replaceAll(RegExp(r'Warning:\s*mysqli_num_rows\(\).*?on line\s*\d+'), '')
        .replaceAll(RegExp(r'Notice:\s*[^<]+on line\s*\d+'), '')
        .trim();
    if (kDebugMode) print('Cleaned Body (Meetings): $cleanBody');
    try {
      final parsed = jsonDecode(cleanBody);
      final typedParsed = Map<String, dynamic>.from(parsed);
      if (typedParsed['data'] is String) {
        return [];
      }
      return typedParsed['data'] ?? typedParsed;
    } catch (e) {
      if (kDebugMode) print('JSON Parse Error (Meetings): $e\nRaw: $body');
      return [];
    }
  }

  Future<void> _fetchMeetings() async {
    if (widget.userId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID is required')),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse(
      '$baseUrl/my-meeting-expired.php?token=$token&user_id=${widget.userId}',
    );
    if (kDebugMode) print('Fetching expired meetings from: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=1nciicncgu05jlv98kv32ihdor',
        },
      );
      if (kDebugMode) {
        print('Meetings Response Status: ${response.statusCode}');
        print('Meetings Response Headers: ${response.headers}');
        print('Meetings Response Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        setState(() {
          meetings = _parseJsonSafely(response.body);
          isLoading = false;
        });
        if (kDebugMode) print('Parsed Meetings: ${meetings.length} items');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load meetings: ${response.statusCode}'),
            ),
          );
        }
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching meetings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching meetings: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : meetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expired meetings found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have no expired meetings at this time.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    meeting['meeting_id']?.toString() ?? 'No ID',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Expired',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Title: ${meeting['title'] ?? 'No Title'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${meeting['date']?.split(' ')[0] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
