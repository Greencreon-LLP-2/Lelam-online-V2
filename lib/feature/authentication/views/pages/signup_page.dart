import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        const bool isTestMode = kDebugMode;
        String testOtp = '9021'; // For testing

        if (isTestMode) {
          if (mounted) {
            context.pushNamed(
              RouteNames.otpVerificationPage,
              extra: {
                'phone': '+91${_phoneController.text}',
                'testOtp': testOtp,
                'userId': null,
              },
            );
            Fluttertoast.showToast(
              msg: 'Test OTP sent: $testOtp',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final headers = {
          'token': '5cb2c9b569416b5db1604e0e12478ded',
          'Cookie': 'PHPSESSID=qn0i8arcee0rhudfamnfodk8qt',
        };

        // Register user
        final registerRequest = http.Request(
          'GET',
          Uri.parse(
            'https://lelamonline.com/admin/api/v1/register.php?token=5cb2c9b569416b5db1604e0e12478ded&mobile_code=91&mobile=${_phoneController.text}',
          ),
        );
        registerRequest.headers.addAll(headers);
        final registerResponse = await registerRequest.send();
        final responseBody = await registerResponse.stream.bytesToString();

        if (registerResponse.statusCode == 200) {
          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse['status'] == true) {
            final userId = jsonResponse['data']?.toString(); // e.g., "525"
            if (userId == null) {
              throw Exception('User ID not found in response');
            }

            // Send OTP
            final otpRequest = http.Request(
              'GET',
              Uri.parse(
                'https://lelamonline.com/admin/api/v1/otp-send.php?token=5cb2c9b569416b5db1604e0e12478ded&mobile_code=91&mobile=${_phoneController.text}&otp=9021',
              ),
            );
            otpRequest.headers.addAll(headers);
            final otpResponse = await otpRequest.send();
            final otpResponseBody = await otpResponse.stream.bytesToString();

            if (otpResponse.statusCode == 200) {
              if (kDebugMode) {
                Fluttertoast.showToast(
                  msg: 'OTP sent: 9021', // Show OTP for testing
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              } else {
                Fluttertoast.showToast(
                  msg: 'OTP sent to ${_phoneController.text}',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.8),
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
              if (mounted) {
                context.pushNamed(
                  RouteNames.otpVerificationPage,
                  extra: {
                    'phone': '+91${_phoneController.text}',
                    'testOtp': null,
                    'userId': userId,
                  },
                );
              }
            } else {
              if (mounted) {
                Fluttertoast.showToast(
                  msg: 'Failed to send OTP: ${otpResponse.reasonPhrase}',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.8),
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
            }
          } else {
            if (mounted) {
              Fluttertoast.showToast(
                msg: 'Registration failed: Invalid response',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.8),
                textColor: Colors.white,
                fontSize: 16.0,
              );
            }
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Error sending OTP: ${registerResponse.reasonPhrase}',
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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your mobile number to sign up',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
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
                            if (value.length != 10) {
                              return 'Please enter a valid 10-digit phone number';
                            }
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'By signing up, you agree to our Terms and Privacy Policy',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
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