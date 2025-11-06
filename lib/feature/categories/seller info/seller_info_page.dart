import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/feature/categories/seller%20info/user_post_page.dart';

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
      // Use the same API endpoint as EditProfilePage
      final response = await ApiService().get(
        url:
            userDetails, // Use userDetails instead of post-seller-information.php
        queryParams: {"user_id": widget.userId},
      );

      if (response['status'] == true && response['code'] == 200) {
        final userData = UserData.fromJson(
          response['data'][0] as Map<String, dynamic>,
        );

        setState(() {
          name = userData.name;
          profileImage =
              (userData.image?.isNotEmpty ?? false)
                  ? "$getImageFromServer${userData.image}"
                  : null;
          noOfPosts = 0; // You'll need to get this from a different API
          activeFrom = userData.createdOn?.split(' ')[0] ?? 'N/A';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Invalid data format';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Seller Information',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black54,
                  strokeWidth: 2,
                ),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Section
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          // Profile Image with shadow - Using same approach as EditProfilePage
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child:
                                  profileImage != null &&
                                          profileImage!.isNotEmpty
                                      ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: profileImage!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Image.asset(
                                                'assets/images/avatar.gif',
                                                fit: BoxFit.cover,
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Image.asset(
                                                    'assets/images/avatar.gif',
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      )
                                      : Image.asset(
                                        'assets/images/avatar.gif',
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Name
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Seller badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Seller',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            // Posts count
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.inventory_2_outlined,
                                label: 'Total Posts',
                                value: noOfPosts.toString(),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[200],
                            ),
                            // Active since
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.calendar_today_outlined,
                                label: 'Active Since',
                                value: activeFrom,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
