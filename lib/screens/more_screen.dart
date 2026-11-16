import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool music = true;
  bool soundEffects = true;
  bool mapLabels = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _menuItem(
          Icons.leaderboard,
          'Papan Peringkat Global',
          'Peringkat simulasi nilai perusahaan',
          () => _showLeaderboard(context),
        ),
        _menuItem(
          Icons.workspace_premium,
          'Toko VIP & Boost',
          'Rewarded Ads dan pembelian lokal untuk testing',
          () => _showInfo(
            context,
            'Fitur pembelian masih berupa simulasi lokal. Tidak ada pembayaran atau iklan sungguhan.',
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'PENGATURAN AUDIO & PETA',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        SwitchListTile(
          value: music,
          onChanged: (value) => setState(() => music = value),
          title: const Text('Musik'),
          activeThumbColor: AppColors.emerald,
        ),
        SwitchListTile(
          value: soundEffects,
          onChanged: (value) => setState(() => soundEffects = value),
          title: const Text('Efek suara'),
          activeThumbColor: AppColors.emerald,
        ),
        SwitchListTile(
          value: mapLabels,
          onChanged: (value) => setState(() => mapLabels = value),
          title: const Text('Label kota'),
          activeThumbColor: AppColors.emerald,
        ),
        const SizedBox(height: 12),
        _menuItem(
          Icons.delete_forever,
          'Reset Progres Lokal',
          'Hapus perusahaan dan save pada perangkat',
          () => _confirmReset(context),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.emerald),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Future<void> _showLeaderboard(BuildContext context) async {
    final entries = await FirebaseService().fetchLeaderboard();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Papan Peringkat Global'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: entries.map((entry) {
            return ListTile(
              leading: Text(
                '#${entry.rank}',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                ),
              ),
              title: Text(entry.companyName),
              subtitle: Text('Level ${entry.level}'),
              trailing: Text('\$${entry.companyValue.toStringAsFixed(0)}'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progres lokal?'),
        content: const Text(
          'Semua progres tersimpan di perangkat ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AppState>().resetProgress();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
