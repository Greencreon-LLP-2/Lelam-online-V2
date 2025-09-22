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
import 'dart:async';
import 'dart:math';

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
  final String _mobileCode = '91'; // Hardcoded mobile code
  final ApiService _apiService = ApiService();
  final HiveHelper _hiveHelper = HiveHelper();
  Timer? _otpTimer;
  int _timerSeconds = 3;
  String? _generatedOtp;
  bool _showOtp = false;
  Timer? _expiryTimer;
  int _expirySeconds = 60;
  bool _isOtpExpired = false;
  final String _countryCode = '91';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    _expiryTimer?.cancel();
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

  // Generate a unique 4-digit OTP
  Future<String> _generateOtp() async {
    final random = Random();
    final otp = (1000 + random.nextInt(9000)).toString();
    final Map<String, dynamic> response = await _apiService.get(
      url: otpSendUrl,
      queryParams: {
        'country_code': _countryCode,
        'mobile': _phoneController.text.trim(),
        'otp': otp,
      },
    );
    // Check if mobile is verified or just existence
    if (response['status'] == 'true') {
      // User exists, proceed to OTP mode
      return otp;
    } else {
      return '';
    }
    // Generates a number between 1000 and 9999
  }

  // Start OTP timer
  void _startOtpTimer() async {
    final otp = await _generateOtp();
    if (otp.isNotEmpty) {
      setState(() {
        _timerSeconds = 3;
        _showOtp = false;
        _generatedOtp = otp; // Generate a new OTP
        _isOtpExpired = false;
        _expirySeconds = 60;
        _otpController.clear(); // Clear previous OTP input
      });

      _otpTimer?.cancel();
      _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _showOtp = true;
            timer.cancel();
            _startExpiryTimer(); // Start expiry timer after OTP is shown
          }
        });
      });
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to generate OTP. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Start OTP expiry timer
  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_expirySeconds > 0) {
          _expirySeconds--;
        } else {
          _isOtpExpired = true;
          timer.cancel();
        }
      });
    });
  }

  // Handle resend OTP
  void _handleResendOtp() {
    _startOtpTimer(); // Generate new OTP and restart timers
    Fluttertoast.showToast(
      msg: 'New OTP sent to +$_mobileCode${_phoneController.text}',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 16.0,
    );
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
          _startOtpTimer(); // Start the OTP timer
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
            _startOtpTimer(); // Start the OTP timer
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
              'Registration failed, Something happened from our end',
            );
          }
        }
      } else {
        if (_isOtpExpired) {
          Fluttertoast.showToast(
            msg: 'OTP has expired. Please request a new OTP.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }

        final inputOtp = _otpController.text;
        if (inputOtp == _generatedOtp) {
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
              msg: 'Login Success, taking you to home page',
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
                  if (_isOtpMode) ...[
                    Center(
                      child: Column(
                        children: [
                          if (_showOtp && _generatedOtp != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Your OTP: $_generatedOtp',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isOtpExpired
                                        ? 'OTP Expired'
                                        : 'OTP expires in $_expirySeconds seconds',
                                    style: TextStyle(
                                      color:
                                          _isOtpExpired
                                              ? Colors.red
                                              : Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_isOtpExpired) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: 160,
                                      child: TextButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : _handleResendOtp,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Resend OTP',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else if (_timerSeconds > 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Receiving OTP in $_timerSeconds seconds',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),
                  Text(
                    _isOtpMode ? 'Verify OTP' : 'Welcome',
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
