import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 80),

              // Logo + App Name
              Column(
                children: [
                  // App Name
                  const Text(
                    'FemCycle',
                    style: TextStyle(
                      fontFamily: 'Magra',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2638),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Logo placeholder (replace with your actual logo image)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF84B2E9),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo not available yet
                          return const _LogoFallback();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tagline
                  const Text(
                    'Every phase begins new energy,\nnew challenges, and new\nopportunities for growth',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 16,
                      color: Color(0xFF6E677D),
                      height: 1.6,
                    ),
                  ),
                ],
              ),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE96A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

// Fallback logo widget until real logo asset is added
class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4E8FE),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular arrows
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF84B2E9),
                  width: 3,
                ),
              ),
            ),
            // Female symbol droplet
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE96A8F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.female,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}