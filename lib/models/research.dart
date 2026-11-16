enum ResearchCategory { efficientEngines, loadingCrew, fleetEngineering, crewTraining, keyClients, dispatchSoftware }

class ResearchDefinition {
  const ResearchDefinition({required this.category, required this.title, required this.description, required this.icon, required this.baseCost});
  final ResearchCategory category;
  final String title, description, icon;
  final double baseCost;
  static const List<ResearchDefinition> all = <ResearchDefinition>[
    ResearchDefinition(category: ResearchCategory.efficientEngines, title: 'Mesin efisien', description: 'Mengurangi konsumsi bahan bakar armada.', icon: 'engine', baseCost: 18000),
    ResearchDefinition(category: ResearchCategory.loadingCrew, title: 'Kru muat', description: 'Mempercepat proses muat dan bongkar.', icon: 'loading', baseCost: 22000),
    ResearchDefinition(category: ResearchCategory.fleetEngineering, title: 'Teknik armada', description: 'Mengurangi keausan dan penuaan kendaraan.', icon: 'engineering', baseCost: 26000),
    ResearchDefinition(category: ResearchCategory.crewTraining, title: 'Pelatihan kru', description: 'Mengurangi biaya gaji harian staf.', icon: 'training', baseCost: 20000),
    ResearchDefinition(category: ResearchCategory.keyClients, title: 'Klien utama', description: 'Meningkatkan pendapatan dari pengantaran.', icon: 'clients', baseCost: 32000),
    ResearchDefinition(category: ResearchCategory.dispatchSoftware, title: 'Software dispatch', description: 'Mengurangi waktu proses dispatcher.', icon: 'software', baseCost: 24000),
  ];
  static ResearchDefinition byCategory(ResearchCategory category) => all.firstWhere((item) => item.category == category);
}

abstract final class ResearchRules {
  static const int maxLevel = 10;
  static double upgradeCost(ResearchCategory category, int currentLevel) => (ResearchDefinition.byCategory(category).baseCost * (currentLevel + 1) * (1 + currentLevel * 0.35)).toDouble();
  static double effectPercent(ResearchCategory category, int level) {
    final factor = switch (category) {
      ResearchCategory.efficientEngines => 2.5,
      ResearchCategory.loadingCrew => 4.0,
      ResearchCategory.fleetEngineering => 3.0,
      ResearchCategory.crewTraining => 3.0,
      ResearchCategory.keyClients => 2.0,
      ResearchCategory.dispatchSoftware => 4.0,
    };
    return level * factor;
  }
}
