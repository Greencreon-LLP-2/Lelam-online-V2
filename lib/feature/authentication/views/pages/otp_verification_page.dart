import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationPage extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const OtpVerificationPage({super.key, this.extra});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasNavigated = false; // Guard to prevent multiple navigations

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

// Inside _OtpVerificationPageState in OtpVerificationPage
Future<void> _handleVerify() async {
  if (_hasNavigated || !_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);
  try {
    final String inputOtp = _otpController.text.trim();
    final String? testOtp = widget.extra?['testOtp'] as String? ?? '9021'; // Fallback to '9021' in release mode
    final String? userId = widget.extra?['userId'] as String?;
    final bool redirectToAuctions = widget.extra?['redirectToAuctions'] as bool? ?? false;

    // Debug logging
    debugPrint('Input OTP: "$inputOtp" (length: ${inputOtp.length})');
    debugPrint('Test OTP: "$testOtp" (length: ${testOtp})');
    debugPrint('User ID: "$userId"');
    debugPrint('Redirect to Auctions: $redirectToAuctions');
    debugPrint('widget.extra: ${widget.extra}');

    if (userId == null || userId.isEmpty) {
      debugPrint('Error: userId is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User ID is missing'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (inputOtp == testOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      _hasNavigated = true;
      if (mounted) {
        context.goNamed(RouteNames.mainscaffold, extra: {'userId': userId});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP verified successfully'),
          backgroundColor: Colors.green.withOpacity(0.8),
        ),
      );
    } else {
      debugPrint('Invalid OTP: inputOtp ($inputOtp) does not match testOtp ($testOtp)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid OTP. Please check and try again.'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error during OTP verification: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final String phone = widget.extra?['phone'] as String? ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Verify OTP',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to $phone',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the OTP';
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
                    return 'OTP must be a 4-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading || _hasNavigated ? null : _handleVerify,
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
                          : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
