import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class SupportTicketPage extends StatefulWidget {
  final String userId;

  const SupportTicketPage({super.key, required this.userId});

  @override
  _SupportTicketPageState createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage> {
  final String baseUrl = "https://your-domain.com/api"; // Replace with your actual base URL
  String token = "";
  List<dynamic> tickets = [];

  @override
  void initState() {
    super.initState();
    _loadConfigAndFetchTickets();
  }

  Future<void> _loadConfigAndFetchTickets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token') ?? '';
    });

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token missing. Please log in again.')),
      );
      return;
    }

    await _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    if (widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is required')),
      );
      return;
    }
    final url = Uri.parse('$baseUrl/support-ticket-list.php?token=$token&user_id=${widget.userId}');
    if (kDebugMode) print('Fetching tickets from: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          tickets = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tickets: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching tickets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tickets: $e')),
      );
    }
  }

  void _showAddTicketDialog() {
    final subjectController = TextEditingController(text: 'Test subjectasdasd');
    final mobileController = TextEditingController(text: '9020583271');
    final messageController = TextEditingController(text: 'test messageasdad');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (widget.userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User ID is required')),
                );
                return;
              }
              if (token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Authentication token missing')),
                );
                return;
              }
              final url = Uri.parse(
                '$baseUrl/add-ticket.php?token=$token&user_id=${widget.userId}&mobile=${mobileController.text}&subject=${Uri.encodeComponent(subjectController.text)}&msg=${Uri.encodeComponent(messageController.text)}',
              );
              if (kDebugMode) print('Creating ticket at: $url');
              try {
                final response = await http.post(url);
                if (response.statusCode == 200) {
                  final responseData = jsonDecode(response.body);
                  Navigator.pop(context);
                  _showTicketCreatedCard(
                    responseData['ticket_id']?.toString() ?? 'N/A',
                    subjectController.text,
                    DateTime.now().toString().split(' ')[0],
                  );
                  await _fetchTickets();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create ticket: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                if (kDebugMode) print('Error creating ticket: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating ticket: $e')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTicketCreatedCard(String ticketId, String subject, String date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ticket Created Successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Ticket ID: $ticketId'),
                const SizedBox(height: 4),
                Text('Subject: $subject'),
                const SizedBox(height: 4),
                Text('Date: $date'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showChatDialog(ticketId, subject, widget.userId);
                    },
                    child: const Text('Open Chat'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChatDialog(String ticketId, String ticketName, String userId) {
    showDialog(
      context: context,
      builder: (context) => ChatDialog(
        baseUrl: baseUrl,
        token: token,
        ticketId: ticketId,
        ticketName: ticketName,
        userId: userId,
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const whatsappNumber = '+1234567890';
    final url = Uri.parse('https://wa.me/$whatsappNumber?text=Hello%20Support');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showAddTicketDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('New Ticket'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tickets.isEmpty
                ? const Center(child: Text('No tickets'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            ticket['subject'] ?? 'No Subject',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'ID: ${ticket['id'] ?? 'N/A'} | ${ticket['status'] ?? 'Unknown'}',
                          ),
                          onTap: () => _showChatDialog(
                            ticket['id']?.toString() ?? 'N/A',
                            ticket['subject'] ?? 'No Subject',
                            widget.userId,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatDialog extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String ticketId;
  final String ticketName;
  final String userId;

  const ChatDialog({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.ticketId,
    required this.ticketName,
    required this.userId,
  });

  @override
  _ChatDialogState createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  List<dynamic> comments = [];
  final commentController = TextEditingController(text: 'Any updates');

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final url = Uri.parse('${widget.baseUrl}/ticket-comments.php?token=${widget.token}&ticket_id=${widget.ticketId}');
    if (kDebugMode) print('Fetching comments from: $url');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching comments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching comments: $e')),
      );
    }
  }

  Future<void> _sendReply() async {
    final comment = commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply')),
      );
      return;
    }
    final url = Uri.parse(
      '${widget.baseUrl}/ticket-reply.php?token=${widget.token}&user_id=${widget.userId}&ticket_id=${widget.ticketId}&comment=${Uri.encodeComponent(comment)}&image=',
    );
    if (kDebugMode) print('Sending reply to: $url');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        commentController.clear();
        await _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error sending reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reply: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ticket ${widget.ticketId} - ${widget.ticketName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: comments.isEmpty
                  ? const Center(child: Text('No comments'))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                comments[index]['comment'] ?? 'No Comment',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Type reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _sendReply,
          child: const Text('Send'),
        ),
      ],
    );
  }
}