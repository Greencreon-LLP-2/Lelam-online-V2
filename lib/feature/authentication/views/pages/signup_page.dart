import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _normalizeMobileNumber(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';
    return mobile
        .replaceAll('+91', '')
        .replaceAll('91', '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '')
        .replaceAll(RegExp(r'^\+?0*'), '')
        .trim();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) print('Form validation failed');
      Fluttertoast.showToast(
        msg: 'Please enter valid details',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      const String baseUrl = 'https://lelamonline.com/admin/api/v1';
      const String token = '5cb2c9b569416b5db1604e0e12478ded';
      final String mobile = _phoneController.text;
      final String name = _nameController.text;
      final String normalizedMobile = _normalizeMobileNumber(mobile);

      if (kDebugMode) print('SignUp - Entered mobile: "$mobile", Name: "$name"');

      // Call signup API (assumed endpoint)
      final signupRequest = http.Request(
        'POST',
        Uri.parse('$baseUrl/signup.php?token=$token'),
      );
      signupRequest.headers.addAll({
        'Cookie': 'PHPSESSID=qn0i8arcee0rhudfamnfodk8qt',
        'Content-Type': 'application/json',
      });
      signupRequest.body = jsonEncode({
        'mobile': normalizedMobile,
        'mobile_code': '91',
        'name': name,
      });

      final signupResponse = await signupRequest.send();
      final signupResponseBody = await signupResponse.stream.bytesToString();

      if (signupResponse.statusCode == 200) {
        if (kDebugMode) print('signup.php response: $signupResponseBody');
        final responseData = jsonDecode(signupResponseBody);
        if (responseData['status'] != 'true' || responseData['user_id'] == null) {
          throw Exception('Signup failed: ${responseData['message'] ?? 'Unknown error'}');
        }

        final userId = responseData['user_id'].toString();
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Signup successful, OTP sent to +91$mobile',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          context.pushNamed(
            RouteNames.otpVerificationPage,
            extra: {
              'phone': '+91$mobile',
              'testOtp': kDebugMode ? '9021' : null,
              'userId': userId,
            },
          );
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Signup failed: ${signupResponse.reasonPhrase}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
        if (kDebugMode) print('signup.php failed: ${signupResponse.statusCode} ${signupResponse.reasonPhrase}');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      if (kDebugMode) print('Error in _handleSignUp: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new account',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    errorStyle: const TextStyle(height: 0.8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 20, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text('+91', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            errorStyle: const TextStyle(height: 0.8),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your phone number';
                            if (value.length < 10) return 'Please enter a valid phone number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: () => context.pushNamed(RouteNames.loginPage),
                    child: Text(
                      'Already have an account? Log In',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}