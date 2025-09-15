
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageFadeAnimation;
  late Animation<Offset> _brandSlideAnimation;

  @override
  void initState() {
    super.initState();
    print('SplashScreen initialized'); // Debug print
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _imageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _brandSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        print('Attempting to navigate to ${RouteNames.mainscaffold}'); // Debug print
        try {
          context.go(RouteNames.mainscaffold);
        } catch (e) {
          print('Navigation error: $e'); 
        }
      } else {
        print('Widget not mounted, skipping navigation');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
backgroundColor: Color(0xFF3261AB),


      body: Stack(
        children: [
          // Center the logo and brand name
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _imageFadeAnimation,
                  child: Image.asset(
                    'assets/images/lelam_logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 20),
                // SlideTransition(
                //   position: _brandSlideAnimation,
                //   child: const Text(
                //     'LelamOnline',
                //     style: TextStyle(
                //       fontSize: 24,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.black87,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          // Bottom text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Green Creone LLP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // Green color to match branding
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}