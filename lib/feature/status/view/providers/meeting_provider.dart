import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeetingsProvider extends ChangeNotifier {
  final List<String> statuses = [
    'Date Fixed',
    'Meeting Request',
    'Awaiting Location',
    'Ready For Meeting',
    'Meeting Completed',
  ];

  int selectedIndex = 0;
  List<Map<String, dynamic>> meetings = [];
  String? errorMessage;
  bool isLoading = true;

  final String? postId;
  final String? bidId;
  final String? userId;
  final Map<String, dynamic>? bid;

  MeetingsProvider({
    this.postId,
    this.bidId,
    this.userId,
    this.bid,
    String? initialStatus,
  }) {
    if (initialStatus != null && statuses.contains(initialStatus)) {
      selectedIndex = statuses.indexOf(initialStatus);
    }
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    isLoading = true;
    errorMessage = null;
    meetings = [];
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> meetingStrings = prefs.getStringList('userMeetings') ?? [];
      meetings = meetingStrings
          .map((meeting) => jsonDecode(meeting) as Map<String, dynamic>)
          .toList();

      // filter
      if (postId != null) {
        meetings = meetings.where((m) => m['post_id'] == postId).toList();
      }
      if (bidId != null) {
        meetings = meetings.where((m) => m['bid_id'] == bidId).toList();
      }

      // add bid if needed
      if (bid != null && statuses[selectedIndex] == 'Meeting Request') {
        final exists = meetings.any(
          (m) => m['post_id'] == postId && (bidId == null || m['bid_id'] == bidId),
        );
        if (!exists) {
          meetings.add({
            'id': bidId ?? 'TEMP_${postId}_${DateTime.now().millisecondsSinceEpoch}',
            'post_id': postId,
            'bid_id': bidId,
            'user_id': userId,
            'status': '1',
            'meeting_done': '0',
            'if_location_request': '0',
            'seller_approvel': '0',
            'admin_approvel': '0',
            'meeting_date': bid!['meeting_date'] ??
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'meeting_time': bid!['meeting_time'] ?? 'N/A',
            'bid_amount': bid!['bidPrice'] ?? '0',
            'with_bid': bid!['with_bid'] ?? '0',
            'title': bid!['title'] ?? 'N/A',
            'carImage': bid!['carImage'] ?? '',
            'appId': bid!['appId'] ?? 'N/A',
            'bidDate': bid!['bidDate'] ?? 'N/A',
            'expirationDate': bid!['expirationDate'] ?? 'N/A',
            'targetPrice': bid!['targetPrice'] ?? '0',
            'bidPrice': bid!['bidPrice'] ?? '0',
            'location': bid!['location'] ?? 'N/A',
            'store': bid!['store'] ?? 'N/A',
          });
          final meetingStrings = meetings.map((m) => jsonEncode(m)).toList();
          await prefs.setStringList('userMeetings', meetingStrings);
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = "Error loading meetings: $e";
      notifyListeners();
    }
  }

  void changeStatus(int index) {
    selectedIndex = index;
    loadMeetings();
  }

  List<Map<String, dynamic>> get filteredMeetings {
    final status = statuses[selectedIndex];
    return meetings.where((meeting) {
      if (status == 'Date Fixed') {
        return meeting['status'] == '1' &&
            meeting['meeting_done'] == '0' &&
            meeting['if_location_request'] == '0' &&
            meeting['seller_approvel'] == '0' &&
            meeting['admin_approvel'] == '0' &&
            !meeting['id'].toString().startsWith('TEMP_');
      } else if (status == 'Meeting Request') {
        return meeting['status'] == '1' &&
            meeting['if_location_request'] == '0' &&
            meeting['seller_approvel'] == '0' &&
            meeting['admin_approvel'] == '0';
      } else if (status == 'Awaiting Location') {
        return meeting['status'] == '1' && meeting['if_location_request'] == '1';
      } else if (status == 'Ready For Meeting') {
        return meeting['status'] == '1' &&
            meeting['seller_approvel'] == '1' &&
            meeting['admin_approvel'] == '1' &&
            meeting['meeting_done'] == '0';
      } else if (status == 'Meeting Completed') {
        return meeting['meeting_done'] == '1';
      }
      return false;
    }).toList();
  }

  // 🔹 Actions
  Future<void> editTime(String id, String meetingTime) async {
    if (!RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(meetingTime)) {
      throw Exception('Invalid time format. Use HH:mm:ss');
    }
    final prefs = await SharedPreferences.getInstance();
    meetings.removeWhere((m) => m['id'] == id);
    meetings.add({...meetings.firstWhere((m) => m['id'] == id), 'meeting_time': meetingTime});
    await prefs.setStringList('userMeetings', meetings.map((m) => jsonEncode(m)).toList());
    notifyListeners();
  }

  Future<void> editDate(String id, DateTime picked) async {
    final meetingDate = DateFormat('yyyy-MM-dd').format(picked);
    final prefs = await SharedPreferences.getInstance();
    meetings.removeWhere((m) => m['id'] == id);
    meetings.add({...meetings.firstWhere((m) => m['id'] == id), 'meeting_date': meetingDate});
    await prefs.setStringList('userMeetings', meetings.map((m) => jsonEncode(m)).toList());
    notifyListeners();
  }

  Future<void> sendLocationRequest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    meetings.removeWhere((m) => m['id'] == id);
    meetings.add({...meetings.firstWhere((m) => m['id'] == id), 'if_location_request': '1'});
    await prefs.setStringList('userMeetings', meetings.map((m) => jsonEncode(m)).toList());
    notifyListeners();
  }

  Future<void> proceedWithBid(String id) async {
    final prefs = await SharedPreferences.getInstance();
    meetings.removeWhere((m) => m['id'] == id);
    meetings.add({
      ...meetings.firstWhere((m) => m['id'] == id),
      'seller_approvel': '1',
      'admin_approvel': '1',
    });
    await prefs.setStringList('userMeetings', meetings.map((m) => jsonEncode(m)).toList());
    notifyListeners();
  }

  Future<void> cancelMeeting(String id) async {
    final prefs = await SharedPreferences.getInstance();
    meetings.removeWhere((m) => m['id'] == id);
    await prefs.setStringList('userMeetings', meetings.map((m) => jsonEncode(m)).toList());
    notifyListeners();
  }
}
