import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkRememberedSession();
  }

  // Skip straight to Home only if the user ticked "Remember me" last time
  // AND a saved auth token still exists. Otherwise any leftover session is
  // cleared and the normal splash -> login flow is shown.
  Future<void> _checkRememberedSession() async {
    final goHome = await ApiService.hasRememberedSession();

    if (!mounted) return;

    if (goHome) {
      // initialize() must run here too, since login_screen.dart's
      // post-login call won't run on this path.
      await NotificationService.initialize();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _checkingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: Glass.pageBackground,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            Center(
              child: CircularProgressIndicator(color: Glass.blueDeep),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 60),

                  // Logo + App Name, in a frosted glass card
                  Glass.card(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 36),
                    child: Column(
                      children: [
                        // App Name
                        Text(
                          'FemCycle',
                          style: Glass.heading(size: 36),
                        ),
                        const SizedBox(height: 30),

                        // Logo
                        Glass.frostedCircle(
                          size: 140,
                          child: Image.asset(
                            'assets/icon/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if logo not available yet
                              return const _LogoFallback();
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Tagline
                        Text(
                          'Every phase begins new energy,\nnew challenges, and new\nopportunities for growth',
                          textAlign: TextAlign.center,
                          style: Glass.body(
                            size: 16,
                            color: Glass.textMuted,
                          ).copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  // Get Started Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60, top: 32),
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
                          backgroundColor: Glass.pinkDeep,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Get Started',
                          style: Glass.heading(
                            size: 18,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      color: Colors.white.withOpacity(0.4),
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
                  color: Glass.blueDeep,
                  width: 3,
                ),
              ),
            ),
            // Female symbol droplet
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Glass.pinkDeep,
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