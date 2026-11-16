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
    return Scaffold(
      body: SafeArea(child: Column(children: [
        const AppHeader(),
        Expanded(child: IndexedStack(index: tab, children: const [
          HqScreen(), MapScreen(), ContractsScreen(), FleetScreen(),
          StaffScreen(), MoreScreen(), ChatScreen(),
        ])),
      ])),
      bottomNavigationBar: const BottomNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _Toast(),
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final message = context.watch<AppState>().toastMessage;
    if (message != null) {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted && context.read<AppState>().toastMessage == message) {
          context.read<AppState>().clearToast();
        }
      });
    }
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final message = context.select<AppState, String?>((state) => state.toastMessage);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 65, left: 15, right: 15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(onTap: context.read<AppState>().clearToast, child: Text(message)),
      ),
    );
  }
}