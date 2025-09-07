import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const LoginPage({super.key, this.extra});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isOtpMode = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Normalize mobile number by removing country code, spaces, or special characters
  String _normalizeMobileNumber(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';
    return mobile
        .replaceAll('+91', '')
        .replaceAll('91', '')
        .replaceAll(
          RegExp(r'[\s\-\(\)]'),
          '',
        ) // Remove spaces, dashes, parentheses
        .replaceAll(RegExp(r'^\+?0*'), '') // Remove leading zeros or +
        .trim();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('Form validation failed');
      }
      Fluttertoast.showToast(
        msg: 'Please enter a valid phone number',
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
      if (_isOtpMode) {
        const bool isTestMode = kDebugMode;
        const String testOtp = '9021';
        const String baseUrl = 'https://lelamonline.com/admin/api/v1';
        const String token = '5cb2c9b569416b5db1604e0e12478ded';
        final String mobile = _phoneController.text;
        final String normalizedMobile = _normalizeMobileNumber(mobile);

        if (kDebugMode) {
          print(
            'Entered mobile: "$mobile", Normalized mobile: "$normalizedMobile"',
          );
        }

        // Step 1: Check if the phone number is registered using index.php
        final userCheckRequest = http.Request(
          'GET',
          Uri.parse('$baseUrl/index.php?token=$token'),
        );
        userCheckRequest.headers.addAll({
          'Cookie': 'PHPSESSID=qn0i8arcee0rhudfamnfodk8qt',
        });
        final userCheckResponse = await userCheckRequest.send();
        final userCheckResponseBody =
            await userCheckResponse.stream.bytesToString();

        if (userCheckResponse.statusCode == 200) {
          dynamic userListResponse;
          try {
            userListResponse = jsonDecode(userCheckResponseBody);
          } catch (e) {
            if (kDebugMode) {
              print('Failed to parse index.php response: $e');
            }
            throw Exception('Failed to parse response from index.php: $e');
          }

          // Check if response has the expected structure
          if (userListResponse is! Map ||
              userListResponse['status'] != 'true' ||
              userListResponse['data'] is! List) {
            if (kDebugMode) {
              print('Invalid response structure: $userListResponse');
            }
            throw Exception(
              'Invalid user list format: Expected a map with status "true" and data as a list',
            );
          }

          final userList = userListResponse['data'] as List<dynamic>;
          Map<String, dynamic> user = {};
          for (var u in userList) {
            final apiMobile = _normalizeMobileNumber(u['mobile']?.toString());
            final apiMobileCode = u['mobile_code']?.toString() ?? '';
            if (kDebugMode) {
              print(
                'Comparing API mobile: "$apiMobile" (code: "$apiMobileCode") with input: "$normalizedMobile"',
              );
            }
            if (apiMobile == normalizedMobile &&
                (apiMobileCode == '91' || apiMobileCode.isEmpty)) {
              user = u as Map<String, dynamic>;
              break;
            }
          }

          if (user.isEmpty) {
            if (mounted) {
              Fluttertoast.showToast(
                msg: 'Phone number not registered. Please sign up.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.8),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
            if (kDebugMode) {
              print('No user found for mobile: $normalizedMobile');
            }
            return;
          }

          final userId = user['user_id']?.toString();
          if (userId == null) {
            if (kDebugMode) {
              print('User found but user_id is null: $user');
            }
            throw Exception('User ID not found');
          }

          if (kDebugMode) {
            print('Found user with user_id: $userId');
          }

          // Step 2: Use test OTP and navigate to OtpVerificationPage
          if (mounted) {
            // Create a new map to avoid modifying widget.extra
            final extra = <String, dynamic>{
              ...?widget.extra, // Spread existing extra, if any
              'phone': '+91$mobile',
              'testOtp': isTestMode ? testOtp : null,
              'userId': userId,
            };
            context.pushNamed(RouteNames.otpVerificationPage, extra: extra);
            Fluttertoast.showToast(
              msg:
                  isTestMode
                      ? 'Test OTP sent: $testOtp'
                      : 'OTP sent to +91$mobile',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Failed to check user: ${userCheckResponse.reasonPhrase}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
          if (kDebugMode) {
            print(
              'index.php failed: ${userCheckResponse.statusCode} ${userCheckResponse.reasonPhrase}',
            );
          }
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Password login not supported',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
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
      if (kDebugMode) {
        print('Error in _handleSubmit: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Use Password',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: !_isOtpMode,
                      onChanged: (value) {
                        setState(() {
                          _isOtpMode = !value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Use OTP',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                            Icon(
                              Icons.phone,
                              size: 20,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+91',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            errorStyle: const TextStyle(height: 0.8),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isOtpMode) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        errorStyle: const TextStyle(height: 0.8),
                      ),
                      validator: (value) {
                        if (!_isOtpMode && (value == null || value.isEmpty)) {
                          return 'Please enter your password';
                        }
                        if (!_isOtpMode && value != null && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              _isOtpMode ? 'Send OTP' : 'Sign In',
                              style: const TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'By continuing, you agree to our Terms and Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          context.pushNamed(RouteNames.signupPage);
                        },
                        child: Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
