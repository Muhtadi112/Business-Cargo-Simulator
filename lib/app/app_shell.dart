import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import '../screens/chat_screen.dart';
import '../screens/contracts_screen.dart';
import '../screens/fleet_screen.dart';
import '../screens/hq_screen.dart';
import '../screens/map_screen.dart';
import '../screens/more_screen.dart';
import '../screens/staff_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.select<AppState, int>((state) => state.selectedTab);
    final hasCompany = context.select<AppState, bool>(
      (state) => state.company != null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: const SafeArea(
          bottom: false,
          child: AppHeader(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (!hasCompany)
              const Center(child: CircularProgressIndicator())
            else
              IndexedStack(
                index: tab,
                children: const [
                  HqScreen(),
                  MapScreen(),
                  ContractsScreen(),
                  FleetScreen(),
                  StaffScreen(),
                  MoreScreen(),
                  ChatScreen(),
                ],
              ),
            const Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: _Toast(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast();

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  Timer? _timer;
  String? _scheduledMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleDismiss(context.watch<AppState>().toastMessage);
  }

  void _scheduleDismiss(String? message) {
    if (message == null) {
      _scheduledMessage = null;
      _timer?.cancel();
      return;
    }
    if (message == _scheduledMessage) return;
    _scheduledMessage = message;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && context.read<AppState>().toastMessage == message) {
        context.read<AppState>().clearToast();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = context.select<AppState, String?>(
      (state) => state.toastMessage,
    );
    if (message == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: context.read<AppState>().clearToast,
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
