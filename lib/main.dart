import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app_shell.dart';
import 'app/app_state.dart';
import 'screens/create_company_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const BusinessCargoSimulatorApp());
}

class BusinessCargoSimulatorApp extends StatelessWidget {
  const BusinessCargoSimulatorApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) {
      final state = AppState();
      unawaited(state.initialize());
      return state;
    },
    child: MaterialApp(
      title: 'Business Cargo Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppGate(),
    ),
  );
}

class _AppGate extends StatelessWidget {
  const _AppGate();
  @override
  Widget build(BuildContext context) => Consumer<AppState>(
    builder: (context, state, _) {
      if (!state.isInitialized) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.emerald)));
      }
      return state.hasCompany ? const AppShell() : const CreateCompanyScreen();
    },
  );
}
