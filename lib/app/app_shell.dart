import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import '../screens/hq_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.select<AppState, int>((state) => state.selectedTab);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: IndexedStack(
                index: index,
                children: const [
                  HqScreen(),
                  _Placeholder(icon: Icons.public, title: 'PETA JARINGAN', detail: 'Peta interaktif hadir pada Tahap 4.'),
                  _Placeholder(icon: Icons.assignment, title: 'BURSA KONTRAK', detail: 'Bursa kontrak pengiriman hadir pada Tahap 4.'),
                  _Placeholder(icon: Icons.local_shipping, title: 'GARASI ARMADA', detail: 'Manajemen armada hadir pada Tahap 4.'),
                  _Placeholder(icon: Icons.groups, title: 'MANAJEMEN STAF', detail: 'Manajemen staf hadir pada Tahap 4.'),
                  _Placeholder(icon: Icons.grid_view, title: 'LAINNYA', detail: 'Fitur tambahan hadir pada Tahap 4.'),
                  _Placeholder(icon: Icons.chat, title: 'LIVE CHAT', detail: 'Live chat hadir pada Tahap 4.'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _ToastOverlay(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.emerald, size: 36),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            const Text('FITUR TAHAP BERIKUTNYA', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay();
  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  Timer? _timer;
  String? _lastMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final message = context.watch<AppState>().toastMessage;
    if (message != null && message != _lastMessage) {
      _lastMessage = message;
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted && context.read<AppState>().toastMessage == message) {
          context.read<AppState>().clearToast();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = context.select<AppState, String?>((state) => state.toastMessage);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 66, left: 16, right: 16),
      child: Material(
        color: AppColors.surfaceElevated,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: context.read<AppState>().clearToast,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emerald.withValues(alpha: .5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle),
                ),
                const SizedBox(width: 9),
                Flexible(child: Text(message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
