import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late ApiService apiService;
  late LoggedUserProvider _userProvider;
  List<Map<String, dynamic>> notificationsList = [];
  bool isLoading = true;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    apiService = ApiService();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    try {
      final Map<String, dynamic> data = await apiService.get(
        url: notifications,
        queryParams: {"user_id": _userProvider.userId},
      );

      final statusRaw = data['status'];
      final bool success =
          statusRaw == true ||
          statusRaw == 'true' ||
          statusRaw == 1 ||
          statusRaw == '1';

      if (success && data['data'] != null) {
        setState(() {
          notificationsList = List<Map<String, dynamic>>.from(data['data']);
          totalCount = data['total_count'] ?? notificationsList.length;
        });
      } else {
        setState(() {
          notificationsList = [];
          totalCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching Notifications: $e');
      setState(() {
        notificationsList = [];
        totalCount = 0;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications ($totalCount)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notificationsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No Notifications Found'),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () async => await fetchNotifications(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: notificationsList.length,
                    itemBuilder: (context, index) {
                      final notif = notificationsList[index];
                      final title = notif['title'] ?? 'No Title';
                      final message = notif['msg'] ?? 'No Message';
                      final createdOn = _parseDate(notif['created_on']);
                      final status = notif['status']?.toString() ?? '0';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.notifications,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (createdOn != null)
                                    Text(
                                      dateFormat.format(createdOn),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == '1'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status == '1' ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: status == '1'
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
