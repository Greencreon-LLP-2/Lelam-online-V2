import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/user_post_page.dart';

const String baseUrl = 'https://lelamonline.com/admin/api/v1';
const String token = '5cb2c9b569416b5db1604e0e12478ded';

class SellerInformationPage extends StatefulWidget {
  final String userId;

  const SellerInformationPage({super.key, required this.userId});

  @override
  _SellerInformationPageState createState() => _SellerInformationPageState();
}

class _SellerInformationPageState extends State<SellerInformationPage> {
  String name = '';
  String? profileImage;
  int noOfPosts = 0;
  String activeFrom = '';
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchSellerInfo();
  }

  Future<void> fetchSellerInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/post-seller-information.php?token=$token&user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' &&
            jsonResponse['data'] is List &&
            jsonResponse['data'].isNotEmpty) {
          final data = jsonResponse['data'][0];
          setState(() {
            name = data['name'] ?? 'Unknown';
            profileImage = data['profile_image'];
            noOfPosts = data['no_post'] ?? 0;
            activeFrom = data['active_from'] ?? 'N/A';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Invalid data format';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load seller information';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void navigateToPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPostsPage(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Information')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          profileImage != null && profileImage!.isNotEmpty
                              ? CachedNetworkImageProvider(profileImage!)
                              : const AssetImage('assets/images/avatar.gif')
                                  as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posts: $noOfPosts',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active Since: $activeFrom',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: navigateToPosts,
                      child: const Text('Show User\'s Posts'),
                    ),
                  ],
                ),
              ),
    );
  }
}
