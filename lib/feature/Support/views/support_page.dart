import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SupportTicketPage extends StatefulWidget {
  final String userId;

  const SupportTicketPage({super.key, required this.userId});

  @override
  _SupportTicketPageState createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage> {
  final String baseUrl = "https://lelamonline.com/admin/api/v1";
  String token = "5cb2c9b569416b5db1604e0e12478ded";
  List<dynamic> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('User ID: ${widget.userId}');
    _loadConfigAndFetchTickets();
  }

  Future<void> _loadConfigAndFetchTickets() async {
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

    await _fetchTickets();
  }

  List<dynamic> _parseJsonSafely(String body) {
    String cleanBody =
        body
            .replaceAll(RegExp(r'<br\s*/?>', multiLine: true), '')
            .replaceAll(RegExp(r'<b>|</b>', multiLine: true), '')
            .replaceAll(
              RegExp(r'Warning:\s*mysqli_num_rows\(\).*?on line\s*\d+'),
              '',
            )
            .replaceAll(RegExp(r'Notice:\s*[^<]+on line\s*\d+'), '')
            .trim();
    if (kDebugMode) print('Cleaned Body (List): $cleanBody');
    try {
      final parsed = jsonDecode(cleanBody);
      final typedParsed = Map<String, dynamic>.from(parsed);
      if (typedParsed['data'] is String) {
        return [];
      }
      return typedParsed['data'] ?? typedParsed;
    } catch (e) {
      if (kDebugMode) print('JSON Parse Error (List): $e\nRaw: $body');
      return [];
    }
  }

  Map<String, dynamic> _parseJsonMapSafely(String body) {
    String cleanBody =
        body
            .replaceAll(RegExp(r'<br\s*/?>', multiLine: true), '')
            .replaceAll(RegExp(r'<b>|</b>', multiLine: true), '')
            .replaceAll(
              RegExp(r'Warning:\s*mysqli_num_rows\(\).*?on line\s*\d+'),
              '',
            )
            .replaceAll(RegExp(r'Notice:\s*[^<]+on line\s*\d+'), '')
            .trim();
    if (kDebugMode) print('Cleaned Body (Map): $cleanBody');
    try {
      final parsed = jsonDecode(cleanBody);
      final typedParsed = Map<String, dynamic>.from(parsed);
      if (kDebugMode) print('Parsed Add Response: $typedParsed');
      return typedParsed;
    } catch (e) {
      if (kDebugMode) print('JSON Parse Error (Map): $e\nRaw: $body');
      return {'success': false, 'ticket_id': 'N/A'};
    }
  }

  Future<void> _fetchTickets() async {
    if (widget.userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User ID is required')));
      }
      setState(() => isLoading = false);
      return;
    }
    final url = Uri.parse(
      '$baseUrl/support-ticket-list.php?token=$token&user_id=${widget.userId}',
    );
    if (kDebugMode) print('Fetching tickets from: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=1nciicncgu05jlv98kv32ihdor',
        },
      );
      if (kDebugMode) {
        print('Tickets Response Status: ${response.statusCode}');
        print('Tickets Response Headers: ${response.headers}');
        print('Tickets Response Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        setState(() {
          tickets = _parseJsonSafely(response.body);
          isLoading = false;
        });
        if (kDebugMode) print('Parsed Tickets: ${tickets.length} items');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load tickets: ${response.statusCode}'),
            ),
          );
        }
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching tickets: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching tickets: $e')));
      }
      setState(() => isLoading = false);
    }
  }

  void _showAddTicketDialog() {
    final subjectController = TextEditingController();
    final mobileController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Create New Ticket'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject *',
                            border: OutlineInputBorder(),
                            hintText: 'Enter ticket subject',
                          ),
                          maxLength: 100,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: mobileController,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 9626040738',
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            labelText: 'Message *',
                            border: OutlineInputBorder(),
                            hintText: 'Describe your issue',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          maxLength: 500,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Defer controller disposal to avoid framework errors
                        Navigator.of(dialogContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          subjectController.dispose();
                          mobileController.dispose();
                          messageController.dispose();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final subject = subjectController.text.trim();
                        final mobile = mobileController.text.trim();
                        final msg = messageController.text.trim();

                        if (subject.isEmpty || mobile.isEmpty || msg.isEmpty) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                          }
                          return;
                        }
                        if (widget.userId.isEmpty) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('User ID is required'),
                              ),
                            );
                          }
                          return;
                        }
                        if (token.isEmpty) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Authentication token missing'),
                              ),
                            );
                          }
                          return;
                        }

                        final url = Uri.parse('$baseUrl/add-ticket.php');
                        if (kDebugMode) print('Creating ticket at: $url');
                        try {
                          final response = await http.post(
                            url,
                            headers: {
                              'token': token,
                              'Cookie': 'PHPSESSID=1nciicncgu05jlv98kv32ihdor',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'user_id': widget.userId,
                              'mobile': mobile,
                              'subject': subject,
                              'msg': msg,
                            }),
                          );
                          if (kDebugMode) {
                            print(
                              'Add Ticket Response Status: ${response.statusCode}',
                            );
                            print(
                              'Add Ticket Response Headers: ${response.headers}',
                            );
                            print('Add Ticket Response Body: ${response.body}');
                          }
                          if (response.statusCode == 200) {
                            final responseData = _parseJsonMapSafely(
                              response.body,
                            );
                            if (responseData['status'] == 'true' &&
                                responseData['code'] == '0') {
                              final newTicketId =
                                  responseData['ticket_id']?.toString() ??
                                  responseData['id']?.toString() ??
                                  'N/A';
                              Navigator.of(dialogContext).pop();
                              // Defer controller disposal
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                subjectController.dispose();
                                mobileController.dispose();
                                messageController.dispose();
                              });
                              if (mounted) {
                                _showTicketCreatedCard(
                                  newTicketId,
                                  subject,
                                  DateTime.now().toString().split(' ')[0],
                                );
                                await _fetchTickets();
                              }
                            } else {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to create ticket: ${responseData['data'] ?? 'Unknown error'}',
                                    ),
                                  ),
                                );
                              }
                            }
                          } else {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to create ticket: ${response.statusCode} - ${response.reasonPhrase}',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (kDebugMode) print('Error creating ticket: $e');
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error creating ticket: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showTicketCreatedCard(String ticketId, String subject, String date) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Card(
              elevation: 4,
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ticket Created Successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Ticket ID: $ticketId'),
                    const SizedBox(height: 4),
                    Text('Subject: $subject'),
                    const SizedBox(height: 4),
                    Text('Date: $date'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showChatDialog(ticketId, subject, widget.userId);
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Open Chat'),
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
    final ticket = tickets.firstWhere(
      (t) => t['id'].toString() == ticketId,
      orElse: () => {'msg': 'No Message'},
    );
    showDialog(
      context: context,
      builder:
          (context) => ChatDialog(
            baseUrl: baseUrl,
            token: token,
            ticketId: ticketId,
            ticketName: ticketName,
            userId: userId,
            initialMessage: ticket['msg'] ?? 'No Message',
          ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const whatsappNumber = '+1234567890';
    final url = Uri.parse('https://wa.me/$whatsappNumber?text=Hello%20Support');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddTicketDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('New Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tickets.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No tickets yet. Create one above!'),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final status =
                            ticket['status'] == '0' ? 'Open' : 'Closed';
                        Color statusColor =
                            status == 'Open' ? Colors.blue : Colors.green;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap:
                                () => _showChatDialog(
                                  ticket['id']?.toString() ?? 'N/A',
                                  ticket['uniq_id'] ?? 'No ID',
                                  widget.userId,
                                ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ticket['uniq_id'] ?? 'No ID',
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
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Subject: ${ticket['subject'] ?? 'No Subject'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${ticket['created_on']?.split(' ')[0] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
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
  final String initialMessage;

  const ChatDialog({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.ticketId,
    required this.ticketName,
    required this.userId,
    required this.initialMessage,
  });

  @override
  _ChatDialogState createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  List<dynamic> comments = [];
  late final TextEditingController commentController;
  final ScrollController _scrollController = ScrollController();
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    comments.add({
      'comment': widget.initialMessage,
      'timestamp': 'Initial Message',
      'isUser': false,
    });
    _fetchComments();
  }

  List<dynamic> _parseJsonSafely(String body) {
    String cleanBody =
        body
            .replaceAll(RegExp(r'<br\s*/?>', multiLine: true), '')
            .replaceAll(RegExp(r'<b>|</b>', multiLine: true), '')
            .replaceAll(
              RegExp(r'Warning:\s*mysqli_num_rows\(\).*?on line\s*\d+'),
              '',
            )
            .replaceAll(RegExp(r'Notice:\s*[^<]+on line\s*\d+'), '')
            .trim();
    if (kDebugMode) print('Cleaned Body (Comments): $cleanBody');
    try {
      final parsed = jsonDecode(cleanBody);
      final typedParsed = Map<String, dynamic>.from(parsed);
      if (typedParsed['data'] is String) {
        return [];
      }
      return (typedParsed['data'] ?? typedParsed)
          .map(
            (comment) => {
              ...comment,
              'isUser': comment['user_id'] == widget.userId,
            },
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('JSON Parse Error (Comments): $e\nRaw: $body');
      return [];
    }
  }

  Future<void> _fetchComments() async {
    final url = Uri.parse(
      '${widget.baseUrl}/ticket-comments.php?token=${widget.token}&ticket_id=${widget.ticketId}',
    );
    if (kDebugMode) print('Fetching comments from: $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=1nciicncgu05jlv98kv32ihdor',
        },
      );
      if (kDebugMode) {
        print('Comments Response Status: ${response.statusCode}');
        print('Comments Response Headers: ${response.headers}');
        print('Comments Response Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final fetchedComments = _parseJsonSafely(response.body);
            comments = [
              {
                'comment': widget.initialMessage,
                'timestamp': 'Initial Message',
                'isUser': false,
              },
              ...fetchedComments,
            ];
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load comments: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching comments: $e')));
      }
    }
  }

  Future<void> _sendReply() async {
    final comment = commentController.text.trim();
    if (comment.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a reply')));
      }
      return;
    }

    setState(() => isSending = true);

    final url = Uri.parse('${widget.baseUrl}/ticket-reply.php');
    if (kDebugMode) print('Sending reply to: $url');
    try {
      final response = await http.post(
        url,
        headers: {
          'token': widget.token,
          'Cookie': 'PHPSESSID=1nciicncgu05jlv98kv32ihdor',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': widget.userId,
          'ticket_id': widget.ticketId,
          'comment': comment,
          'image': '',
        }),
      );
      if (kDebugMode) {
        print('Reply Response Status: ${response.statusCode}');
        print('Reply Response Headers: ${response.headers}');
        print('Reply Response Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent successfully!')),
          );
          Navigator.of(context).pop(); // Close dialog immediately
          await _fetchComments(); // Fetch comments in background
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reply: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error sending reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending reply: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Ticket ${widget.ticketId} - ${widget.ticketName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    comments.isEmpty
                        ? const Center(
                          child: Text(
                            'No messages yet. Start the conversation!',
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12.0),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final isUser = comment['isUser'] ?? false;
                            final timestamp =
                                comment['timestamp'] == 'Initial Message'
                                    ? comment['timestamp']
                                    : DateFormat('MMM d, yyyy HH:mm').format(
                                      DateTime.parse(
                                        comment['timestamp'] ??
                                            DateTime.now().toString(),
                                      ),
                                    );

                            return Align(
                              alignment:
                                  isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 8.0,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Card(
                                  elevation: 2,
                                  color:
                                      isUser ? Colors.blue[50] : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          isUser
                                              ? Colors.blue[200]!
                                              : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          isUser
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              isUser
                                                  ? MainAxisAlignment.end
                                                  : MainAxisAlignment.start,
                                          children: [
                                            if (!isUser)
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.blue,
                                                child: Text(
                                                  'S',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comment['comment'] ??
                                                    'No Comment',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (isUser)
                                              const SizedBox(width: 8),
                                            if (isUser)
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.green,
                                                child: Text(
                                                  'U',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          timestamp,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isSending ? null : _sendReply,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child:
                            isSending
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 24,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [],
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
