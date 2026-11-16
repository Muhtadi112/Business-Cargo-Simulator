import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../models/city.dart';
import '../models/contract.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _worldWidth = 2200;
  static const double _worldHeight = 1100;
  static const double _initialScale = 1.35;

  static const Set<String> _worldHubs = {
    'Jakarta',
    'Singapore',
    'Tokyo',
    'Dubai',
    'Rotterdam',
    'London',
    'New York',
    'Los Angeles',
    'Sao Paulo',
    'Sydney',
  };

  final TransformationController _transformController =
      TransformationController();
  double _currentScale = _initialScale;
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformController
      ..removeListener(_handleTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final wasRegional = _currentScale >= 1.1;
    final isRegional = scale >= 1.1;
    _currentScale = scale;
    if (wasRegional != isRegional && mounted) {
      setState(() {});
    }
  }

  void _initializeCamera(Size viewport, AppState state) {
    if (_cameraInitialized || viewport.isEmpty || state.company == null) {
      return;
    }

    final headquarters = CityCatalog.allCities.firstWhere(
      (city) => city.name == state.company!.headquartersCity,
      orElse: () => CityCatalog.byId('jakarta'),
    );
    final headquartersPoint = _cityCanvasPoint(headquarters);
    final headquartersX = headquartersPoint.dx;
    final headquartersY = headquartersPoint.dy;

    _transformController.value = Matrix4.identity()
      ..translate(
        viewport.width / 2 - headquartersX * _initialScale,
        viewport.height / 2 - headquartersY * _initialScale,
      )
      ..scale(_initialScale);
    _currentScale = _initialScale;
    _cameraInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final company = state.company;
    final missions = <_Mission>[
      _Mission('Beli kendaraan kedua', state.vehicles.length, 2),
      _Mission(
        'Selesaikan 3 kontrak pengiriman',
        company?.completedContracts ?? 0,
        3,
      ),
      _Mission(
        'Buka 2 kota jaringan logistik',
        company?.unlockedCityIds.length ?? 0,
        2,
      ),
      _Mission(
        'Capai nilai perusahaan \$100K',
        (company?.balance ?? 0) + (company?.fleetValue ?? 0),
        100000,
      ),
    ];
    final missionIndex = missions.indexWhere((mission) => !mission.done);
    final mission = missions[missionIndex < 0 ? missions.length - 1 : missionIndex];

    final cities = CityCatalog.allCities;
    final visibleCities = _currentScale < 1.1
        ? cities.where((city) => _worldHubs.contains(city.name)).toList()
        : cities;

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _cameraInitialized) return;
                _initializeCamera(
                  Size(constraints.maxWidth, constraints.maxHeight),
                  context.read<AppState>(),
                );
              });
              return InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.45,
                maxScale: 4.5,
                transformationController: _transformController,
                child: SizedBox(
                  width: _worldWidth,
                  height: _worldHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: Color(0xFF0D151A)),
                      ),
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF132029),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/maps/world_map_dark.png',
                            width: _worldWidth,
                            height: _worldHeight,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                                const CustomPaint(
                              painter: WorldMapFallbackPainter(),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: WorldMapPainter()),
                      ),
                      for (final city in visibleCities)
                        ..._buildCityMarkers(city),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Row(
            children: [
              _chip(Icons.notifications_none, '2'),
              const Spacer(),
              _chip(Icons.ac_unit, 'Musim dingin • sisa 26m 25s'),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      missionIndex < 0
                          ? 'SEMUA TARGET AWAL SELESAI'
                          : 'TARGET BERIKUTNYA • ${missionIndex + 1} DARI ${missions.length}',
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      missionIndex < 0
                          ? 'Lanjutkan ekspansi perusahaan'
                          : '${mission.title} • ${mission.currentLabel} / ${mission.targetLabel}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: mission.progress,
                      color: AppColors.emerald,
                      backgroundColor: AppColors.border,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(Icons.sports_esports, 'Mengemudi'),
                  const SizedBox(width: 7),
                  _chip(Icons.music_note, 'Musik'),
                  const Spacer(),
                  _chip(Icons.emoji_events, '3'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCityMarkers(CityNode city) {
    final point = _cityCanvasPoint(city);
    final x = point.dx;
    final y = point.dy;
    final labelOffset = _cityLabelOffsets[city.name] ?? const Offset(10, -18);
    final isHeadquarters =
        context.read<AppState>().company?.headquartersCity == city.name;
    final isMajor = _worldHubs.contains(city.name);

    return [
      Positioned(
        left: x - 5,
        top: y - 5,
        child: Container(
          width: isMajor || isHeadquarters ? 10 : 7,
          height: isMajor || isHeadquarters ? 10 : 7,
          decoration: BoxDecoration(
            color: isHeadquarters ? AppColors.gold : AppColors.emerald,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.background, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: (isHeadquarters ? AppColors.gold : AppColors.emerald)
                    .withValues(alpha: 0.45),
                blurRadius: 7,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: x + labelOffset.dx,
        top: y + labelOffset.dy,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isHeadquarters
                  ? AppColors.gold.withValues(alpha: 0.65)
                  : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Text(
              city.name,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: isHeadquarters
                    ? AppColors.gold
                    : isMajor
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                fontSize: isMajor ? 11 : 10,
                fontWeight: isMajor || isHeadquarters
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

const Map<String, Offset> _cityLabelOffsets = {
  'London': Offset(-42, -25),
  'Rotterdam': Offset(12, -21),
  'New York': Offset(10, -20),
  'Los Angeles': Offset(-78, -23),
  'Sao Paulo': Offset(12, 4),
  'Dubai': Offset(12, -22),
  'Mumbai': Offset(-48, -27),
  'Bangkok': Offset(12, -22),
  'Hong Kong': Offset(12, -22),
  'Tokyo': Offset(12, -22),
  'Jakarta': Offset(-48, 14),
  'Singapore': Offset(12, 9),
  'Kuala Lumpur': Offset(-72, 19),
  'Sukabumi': Offset(-65, -30),
  'Bandung': Offset(12, -28),
  'Pontianak': Offset(-75, -12),
  'Surabaya': Offset(15, 8),
  'Makassar': Offset(17, -13),
  'Sydney': Offset(12, -20),
};

class _Mission {
  const _Mission(this.title, this.current, this.target);

  final String title;
  final num current;
  final num target;

  bool get done => current >= target;

  double get progress =>
      (current / target).clamp(0.0, 1.0).toDouble();

  String get currentLabel => _label(current);

  String get targetLabel => _label(target);

  String _label(num value) => value >= 1000
      ? '${(value / 1000).toStringAsFixed(0)}K'
      : value.toStringAsFixed(0);
}

Widget _chip(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.emerald),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );


Offset _cityCanvasPoint(CityNode city) => Offset(
      ((city.longitude + 180) / 360) * 2200,
      ((90 - city.latitude) / 180) * 1100,
    );

class WorldMapPainter extends CustomPainter {
  const WorldMapPainter({this.contracts = const []});

  final List<CargoContract> contracts;

  static const List<(String, String)> _routes = [
    ('Los Angeles', 'New York'), ('New York', 'London'),
    ('London', 'Rotterdam'), ('Rotterdam', 'Dubai'),
    ('Dubai', 'Mumbai'), ('Mumbai', 'Singapore'),
    ('Singapore', 'Bangkok'), ('Singapore', 'Hong Kong'),
    ('Hong Kong', 'Tokyo'), ('Singapore', 'Jakarta'),
    ('Jakarta', 'Kuala Lumpur'), ('Jakarta', 'Pontianak'),
    ('Jakarta', 'Bandung'), ('Bandung', 'Sukabumi'),
    ('Bandung', 'Surabaya'), ('Surabaya', 'Makassar'),
    ('Makassar', 'Sydney'), ('New York', 'Sao Paulo'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cities = {for (final city in CityCatalog.allCities) city.name: city};
    final routePaint = Paint()
      ..color = const Color(0xA6336B72)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final route in _routes) {
      final origin = cities[route.$1];
      final destination = cities[route.$2];
      if (origin == null || destination == null) continue;
      final start = _cityCanvasPoint(origin);
      final end = _cityCanvasPoint(destination);
      final control = Offset((start.dx + end.dx) / 2, start.dy - 35);
      canvas.drawPath(
        Path()..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
        routePaint,
      );
    }
    final pulsePaint = Paint()
      ..color = const Color(0x5533E5A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final city in CityCatalog.allCities) {
      final point = _cityCanvasPoint(city);
      canvas.drawCircle(point, 10, pulsePaint);
      pulsePaint.color = const Color(0x2233E5A0);
      canvas.drawCircle(point, 15, pulsePaint);
      pulsePaint.color = const Color(0x5533E5A0);
    }

    final citiesById = {for (final city in CityCatalog.allCities) city.id: city};
    final now = DateTime.now().toUtc();
    final vehiclePaint = Paint()..color = const Color(0xFFFFC857);
    for (final contract in contracts) {
      if (contract.status != ContractStatus.inTransit) continue;
      final departure = contract.departureTimeUtc;
      final arrival = contract.arrivalTimeUtc;
      final origin = citiesById[contract.originCityId];
      final destination = citiesById[contract.destinationCityId];
      if (departure == null || arrival == null || origin == null || destination == null) continue;
      final duration = arrival.difference(departure).inMilliseconds;
      if (duration <= 0) continue;
      final progress = (now.difference(departure).inMilliseconds / duration)
          .clamp(0.0, 1.0)
          .toDouble();
      final start = _cityCanvasPoint(origin);
      final end = _cityCanvasPoint(destination);
      final point = Offset(
        start.dx + (end.dx - start.dx) * progress,
        start.dy + (end.dy - start.dy) * progress,
      );
      canvas.drawCircle(point, 7, vehiclePaint);
      canvas.drawCircle(
        point,
        11,
        Paint()
          ..color = const Color(0x66FFC857)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) =>
      oldDelegate.contracts != contracts;
}

/// Approximate geographic outlines used only if the Natural Earth raster fails.
class WorldMapFallbackPainter extends CustomPainter {
  const WorldMapFallbackPainter();

  static const _continents = <List<Offset>>[
    [Offset(-168,70),Offset(-150,60),Offset(-132,55),Offset(-125,48),Offset(-123,40),Offset(-117,32),Offset(-108,29),Offset(-105,22),Offset(-97,18),Offset(-90,20),Offset(-84,25),Offset(-80,32),Offset(-75,36),Offset(-67,44),Offset(-60,50),Offset(-65,57),Offset(-78,62),Offset(-95,68),Offset(-115,72),Offset(-140,72)],
    [Offset(-81,12),Offset(-72,10),Offset(-60,7),Offset(-50,2),Offset(-40,-8),Offset(-35,-15),Offset(-40,-25),Offset(-48,-35),Offset(-54,-46),Offset(-66,-55),Offset(-73,-48),Offset(-75,-35),Offset(-78,-20),Offset(-80,-5)],
    [Offset(-10,36),Offset(-10,44),Offset(0,50),Offset(10,55),Offset(20,60),Offset(30,70),Offset(45,72),Offset(60,68),Offset(75,72),Offset(95,75),Offset(120,68),Offset(145,60),Offset(160,55),Offset(170,48),Offset(155,42),Offset(140,38),Offset(130,32),Offset(120,25),Offset(110,20),Offset(105,10),Offset(100,5),Offset(95,10),Offset(90,20),Offset(80,8),Offset(75,10),Offset(70,20),Offset(60,25),Offset(50,30),Offset(40,35),Offset(30,40),Offset(20,38),Offset(10,42),Offset(0,40)],
    [Offset(-17,31),Offset(0,37),Offset(15,34),Offset(30,31),Offset(40,12),Offset(50,0),Offset(42,-12),Offset(35,-25),Offset(25,-35),Offset(17,-34),Offset(10,-25),Offset(0,-5),Offset(-10,5),Offset(-17,20)],
    [Offset(113,-11),Offset(125,-13),Offset(138,-12),Offset(153,-24),Offset(151,-38),Offset(140,-39),Offset(128,-34),Offset(115,-25)],
    [Offset(-52,60),Offset(-42,65),Offset(-35,75),Offset(-42,82),Offset(-55,84),Offset(-65,77),Offset(-60,68)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0xFFFFFFFF);
    final coast = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final polygon in _continents) {
      final path = Path();
      for (var i = 0; i < polygon.length; i++) {
        final coordinate = polygon[i];
        final point = Offset(
          ((coordinate.dx + 180) / 360) * size.width,
          ((90 - coordinate.dy) / 180) * size.height,
        );
        if (i == 0) { path.moveTo(point.dx, point.dy); }
        else { path.lineTo(point.dx, point.dy); }
      }
      path.close();
      canvas.drawPath(path, land);
      canvas.drawPath(path, coast);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapFallbackPainter oldDelegate) => false;
}
