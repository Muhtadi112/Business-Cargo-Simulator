import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}
class _StaffScreenState extends State<StaffScreen> {
  int _tab = 0;
  final List<String> _hired = <String>[];
  final List<String> _roles = <String>['Sopir', 'Mekanik', 'Manajer'];
  final List<List<String>> _people = <List<String>>[
    <String>['Raka Pratama', 'Dimas Saputra', 'Arif Nugroho'],
    <String>['Bima Teknisi', 'Rendi Maulana', 'Yoga Firmansyah'],
    <String>['Nadia Putri', 'Salsa Maharani', 'Kevin Wijaya'],
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    Row(children: List.generate(3, (i) => Expanded(child: Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ChoiceChip(label: Text(_roles[i]), selected: _tab == i, onSelected: (_) => setState(() => _tab = i)),
    )))),
    Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13)),
      child: Text('Manajemen SDM • ${_hired.length} staf direkrut', style: const TextStyle(fontWeight: FontWeight.w900))),
    const SizedBox(height: 12),
    const Text('KANDIDAT TERSEDIA', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 10)),
    ...List.generate(3, (i) {
      final name = _people[_tab][i];
      return Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(name),
        subtitle: Text('Skill ${4+i}/5 • bonus ${5+i*3}%\nGaji harian \$${180+i*35}'),
        trailing: FilledButton(onPressed: _hired.contains(name) ? null : () => setState(() => _hired.add(name)), child: const Text('Rekrut')),
      ));
    }),
    const SizedBox(height: 12),
    const Text('STAF PERUSAHAAN', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 10)),
    if (_hired.isEmpty) const Text('Belum ada staf direkrut.', style: TextStyle(color: AppColors.textSecondary))
    else ..._hired.map((name) => ListTile(
      title: Text(name), subtitle: const Text('Penugasan kendaraan belum ditetapkan'),
      trailing: IconButton(onPressed: () => setState(() => _hired.remove(name)), icon: const Icon(Icons.person_remove, color: AppColors.danger)),
    )),
  ]);
}