import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/model/user_model.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';

class LoginDialog extends StatefulWidget {
  final VoidCallback? onSuccess;

  const LoginDialog({super.key, this.onSuccess});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpMode = false;
  final String _mobileCode = '91';
  final ApiService _apiService = ApiService();
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

  String _normalizeMobileNumber(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';
    return mobile
        .replaceAll('+$_mobileCode', '')
        .replaceAll(_mobileCode, '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '')
        .replaceAll(RegExp(r'^\+?0*'), '')
        .trim();
  }

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
    if (response['status'] == 'true') {
      return otp;
    }
    return '';
  }

  void _startOtpTimer() async {
    final otp = await _generateOtp();
    if (otp.isNotEmpty) {
      setState(() {
        _timerSeconds = 3;
        _showOtp = false;
        _generatedOtp = otp;
        _isOtpExpired = false;
        _expirySeconds = 60;
        _otpController.clear();
      });
      _otpTimer?.cancel();
      _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _showOtp = true;
            timer.cancel();
            _startExpiryTimer();
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

  void _handleResendOtp() {
    _startOtpTimer();
    Fluttertoast.showToast(
      msg: 'New OTP sent to +$_mobileCode${_phoneController.text}',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: _isOtpMode ? 'Please enter a valid OTP' : 'Please enter a valid phone number',
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
        final mobile = _normalizeMobileNumber(_phoneController.text);
        final Map<String, dynamic> response = await _apiService.get(
          url: userDetails,
          queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
        );
        if (response['status'] == true && response['code'] == 200) {
          setState(() => _isOtpMode = true);
          _startOtpTimer();
          Fluttertoast.showToast(
            msg: 'OTP sent to +$_mobileCode$mobile',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          final Map<String, dynamic> registerResponse = await _apiService.get(
            url: userRegister,
            queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
          );
          if (registerResponse['status'] == true) {
            setState(() => _isOtpMode = true);
            _startOtpTimer();
            Fluttertoast.showToast(
              msg: 'OTP sent to +$_mobileCode$mobile',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          } else {
            throw Exception('Registration failed, Something happened from our end');
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
          final mobile = _normalizeMobileNumber(_phoneController.text);
          final Map<String, dynamic> response = await _apiService.get(
            url: userDetails,
            queryParams: {'mobile_code': _mobileCode, 'mobile': mobile},
          );
          if (response['status'] == true && response['code'] == 200) {
            final userData = UserData.fromJson(response['data'][0] as Map<String, dynamic>);
            await Provider.of<LoggedUserProvider>(context, listen: false).setUser(userData);
            Fluttertoast.showToast(
              msg: 'Login Success',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
            widget.onSuccess?.call();
            Navigator.of(context).pop();
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
    } catch (e) {
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        _isOtpMode ? 'Verify OTP' : 'Login',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isOtpMode) ...[
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
                          _isOtpExpired ? 'OTP Expired' : 'OTP expires in $_expirySeconds seconds',
                          style: TextStyle(
                            color: _isOtpExpired ? Colors.red : Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isOtpExpired) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 160,
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleResendOtp,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Resend OTP', style: TextStyle(fontSize: 14)),
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
                      style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
              Text(
                _isOtpMode
                    ? 'Enter the OTP sent to +$_mobileCode${_phoneController.text}'
                    : 'Enter your phone number to continue',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              if (!_isOtpMode)
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
                            Text('+$_mobileCode', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
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
              if (_isOtpMode)
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter OTP',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text(_isOtpMode ? 'Verify OTP' : 'Send OTP'),
        ),
      ],
    );
  }
}