import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';

class OtpVerificationPage extends StatefulWidget {
  final Map<String, dynamic> data; // Contains phone, testOtp, userId

  const OtpVerificationPage({super.key, required this.data});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (widget.data['phone'] == null || widget.data['phone'].isEmpty) {
      Fluttertoast.showToast(
        msg: 'Invalid phone number',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Future.microtask(() => context.pop());
    } else {
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
            _startResendTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 4) {
      Fluttertoast.showToast(
        msg: 'Please enter a valid OTP',
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
      const bool isTestMode = kDebugMode;
      final String? testOtp = widget.data['testOtp'];

      if (isTestMode && testOtp != null) {
        if (otp == testOtp) {
          if (mounted) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', widget.data['userId'] ?? 'test_user');
            Fluttertoast.showToast(
              msg: 'Test OTP Verified Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
            context.goNamed(
              RouteNames.mainscaffold,
              extra: widget.data['userId'],
            );
          }
        } else {
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Invalid Test OTP',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
          }
        }
        setState(() => _isLoading = false);
        return;
      }

      final headers = {
        'token': '5cb2c9b569416b5db1604e0e12478ded',
        'Cookie': 'PHPSESSID=qn0i8arcee0rhudfamnfodk8qt',
      };
      final request = http.Request(
        'GET',
        Uri.parse(
          'https://lelamonline.com/admin/api/v1/otp-verify.php?token=5cb2c9b569416b5db1604e0e12478ded&mobile_code=91&mobile=${widget.data['phone'].substring(3)}&otp=$otp',
        ),
      );
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['status'] == 'true') {
          if (mounted) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', widget.data['userId']);
            Fluttertoast.showToast(
              msg: 'OTP Verified Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              textColor: Colors.white,
              fontSize: 16.0,
            );
            context.goNamed(
              RouteNames.mainscaffold,
              extra: widget.data['userId'],
            );
          }
        } else {
          if (mounted) {
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
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Error: ${response.reasonPhrase}',
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

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _canResend = false;
      _resendTimer = 30;
    });

    try {
      const bool isTestMode = kDebugMode;
      String testOtp = '9021';

      final headers = {
        'token': '5cb2c9b569416b5db1604e0e12478ded',
        'Cookie': 'PHPSESSID=qn0i8arcee0rhudfamnfodk8qt',
      };
      final request = http.Request(
        'GET',
        Uri.parse(
          'https://lelamonline.com/admin/api/v1/otp-send.php?token=5cb2c9b569416b5db1604e0e12478ded&mobile_code=91&mobile=${widget.data['phone'].substring(3)}&otp=$testOtp',
        ),
      );
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: isTestMode ? 'Test OTP Resent: $testOtp' : 'OTP Resent Successfully',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
        _startResendTimer();
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Error: ${response.reasonPhrase}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Verify Your Phone',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 4-digit code sent to ${widget.data['phone']}',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey[400]),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          'Verify OTP',
                          style: TextStyle(fontSize: 14),
                        ),
                  ),
                ),
              
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend
                        ? 'Resend OTP'
                        : 'Resend OTP in $_resendTimer seconds',
                    style: TextStyle(
                      color:
                          _canResend ? AppTheme.primaryColor : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}