import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/hive_helper.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';

import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const LoginPage({super.key, this.extra});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpMode = false;
  final String _hardcodedOtp = '9021'; // Hardcoded OTP for testing
  final String _mobileCode = '91'; // Hardcoded mobile code
  final ApiService _apiService = ApiService();
  final HiveHelper _hiveHelper = HiveHelper();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Normalize mobile number
  String _normalizeMobileNumber(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';
    return mobile
        .replaceAll('+$_mobileCode', '')
        .replaceAll(_mobileCode, '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '')
        .replaceAll(RegExp(r'^\+?0*'), '')
        .trim();
  }

  // Handle login or OTP verification
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg:
            _isOtpMode
                ? 'Please enter a valid OTP'
                : 'Please enter a valid phone number',
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
      if (!_isOtpMode) {
        // Step 1: Check if user exists
        final mobile = _normalizeMobileNumber(_phoneController.text);
        final Map<String, dynamic> response = await _apiService.get(
          url: userDetails,
          queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
        );
        // Check if mobile is verified or just existence
        if (response['status'] == true && response['code'] == 200) {
          // User exists, proceed to OTP mode
          setState(() => _isOtpMode = true);
          Fluttertoast.showToast(
            msg: 'OTP sent to +$_mobileCode$mobile',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          // User does not exist, register user
          final Map<String, dynamic> registerResponse = await _apiService.get(
            url: userRegister,
            queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
          );

          if (registerResponse['status'] == true) {
            setState(() => _isOtpMode = true);
            Fluttertoast.showToast(
              msg: 'OTP sent to +$_mobileCode$mobile',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            throw Exception(
              'Registration failed, Somethign happen from our end}',
            );
          }
        }
      } else {

        final inputOtp = _otpController.text;
        if (inputOtp == _hardcodedOtp) {
          // Fetch user data again to ensure we have the latest
          final mobile = _normalizeMobileNumber(_phoneController.text);
          final Map<String, dynamic> response = await _apiService.get(
            url: userDetails,
            queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
          );

          if (response['status'] == true && response['code'] == 200) {
            final userData = UserData.fromJson(
              response['data'][0] as Map<String, dynamic>,
            );

            // Save & notify provider
            await Provider.of<LoggedUserProvider>(
              context,
              listen: false,
            ).setUser(userData);

            context.goNamed(RouteNames.splashPage);
            Fluttertoast.showToast(
              msg: 'Login Sucess taking you to home page',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            Fluttertoast.showToast(
              msg: 'Failed to fetch user data after OTP verification',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Invalid OTP',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    } catch (e, stack) {
      print(stack);

      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() => _isLoading = false);
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    _isOtpMode ? 'Verify OTP' : 'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpMode
                        ? 'Enter the OTP sent to +$_mobileCode${_phoneController.text}'
                        : 'Sign in to continue',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  if (!_isOtpMode) ...[
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
                                  '+$_mobileCode',
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
                  ],
                  if (_isOtpMode) ...[
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter OTP',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        errorStyle: const TextStyle(height: 0.8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 4) {
                          return 'OTP must be 4 digits';
                        }
                        return null;
                      },
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
                                _isOtpMode ? 'Verify OTP' : 'Send OTP',
                                style: const TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'By continuing, you agree to our Terms and Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        if (!_isOtpMode) ...[
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
