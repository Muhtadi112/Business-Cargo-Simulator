import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BusinessCargoSimulatorApp());
}

class BusinessCargoSimulatorApp extends StatelessWidget {
  const BusinessCargoSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Cargo Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _FoundationScreen(),
    );
  }
}

class _FoundationScreen extends StatelessWidget {
  const _FoundationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.emerald),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.emerald,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BUSINESS CARGO SIMULATOR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GLOBAL LOGISTICS & FLEET MANAGEMENT TYCOON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 28),
                const CircularProgressIndicator(color: AppColors.emerald),
                const SizedBox(height: 18),
                const Text(
                  'ADI • FOUNDATION BUILD',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
