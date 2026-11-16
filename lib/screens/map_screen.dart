import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_state.dart';
import '../models/city.dart';
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
    final headquartersX = headquarters.mapX * _worldWidth;
    final headquartersY = headquarters.mapY * _worldHeight;

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
                        child: CustomPaint(
                          size: Size(_worldWidth, _worldHeight),
                          painter: WorldMapPainter(),
                        ),
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
    final x = city.mapX * _worldWidth;
    final y = city.mapY * _worldHeight;
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

class WorldMapPainter extends CustomPainter {
  const WorldMapPainter();

  static const Color _land = Color(0xFF132029);
  static const Color _coast = Color(0xFF223542);
  static const Color _grid = Color(0xFF111B22);

  static const List<List<Offset>> _landmasses = [
    // North America and Central America.
    [
      Offset(.045, .205), Offset(.055, .165), Offset(.082, .135),
      Offset(.116, .112), Offset(.153, .102), Offset(.192, .115),
      Offset(.224, .137), Offset(.254, .168), Offset(.278, .207),
      Offset(.291, .245), Offset(.278, .276), Offset(.253, .296),
      Offset(.238, .329), Offset(.218, .352), Offset(.203, .386),
      Offset(.180, .398), Offset(.157, .372), Offset(.137, .349),
      Offset(.108, .337), Offset(.083, .309), Offset(.062, .273),
    ],
    // South America.
    [
      Offset(.222, .414), Offset(.248, .414), Offset(.275, .434),
      Offset(.297, .469), Offset(.309, .508), Offset(.305, .552),
      Offset(.294, .592), Offset(.284, .635), Offset(.269, .684),
      Offset(.252, .735), Offset(.238, .789), Offset(.220, .847),
      Offset(.204, .872), Offset(.190, .834), Offset(.181, .786),
      Offset(.174, .733), Offset(.166, .681), Offset(.166, .625),
      Offset(.176, .571), Offset(.187, .520), Offset(.196, .468),
    ],
    // Europe and Scandinavia.
    [
      Offset(.414, .213), Offset(.427, .184), Offset(.450, .166),
      Offset(.474, .159), Offset(.494, .170), Offset(.511, .157),
      Offset(.530, .170), Offset(.544, .194), Offset(.559, .211),
      Offset(.552, .237), Offset(.535, .249), Offset(.526, .276),
      Offset(.506, .291), Offset(.486, .283), Offset(.468, .296),
      Offset(.449, .283), Offset(.432, .265), Offset(.417, .244),
    ],
    // Africa.
    [
      Offset(.435, .309), Offset(.462, .292), Offset(.493, .295),
      Offset(.524, .309), Offset(.550, .335), Offset(.565, .372),
      Offset(.569, .413), Offset(.559, .457), Offset(.545, .505),
      Offset(.526, .558), Offset(.509, .613), Offset(.489, .665),
      Offset(.470, .690), Offset(.451, .654), Offset(.437, .607),
      Offset(.420, .557), Offset(.407, .506), Offset(.405, .458),
      Offset(.411, .407), Offset(.417, .357),
    ],
    // Mainland Asia.
    [
      Offset(.531, .205), Offset(.551, .169), Offset(.584, .141),
      Offset(.625, .119), Offset(.674, .112), Offset(.719, .119),
      Offset(.759, .130), Offset(.803, .138), Offset(.846, .157),
      Offset(.886, .174), Offset(.924, .198), Offset(.955, .230),
      Offset(.970, .267), Offset(.959, .300), Offset(.938, .326),
      Offset(.910, .341), Offset(.884, .366), Offset(.851, .367),
      Offset(.827, .350), Offset(.801, .370), Offset(.778, .398),
      Offset(.750, .391), Offset(.725, .371), Offset(.697, .389),
      Offset(.672, .413), Offset(.648, .397), Offset(.626, .376),
      Offset(.601, .358), Offset(.579, .330), Offset(.557, .299),
      Offset(.541, .263),
    ],
    // Arabian peninsula.
    [
      Offset(.562, .390), Offset(.589, .378), Offset(.618, .390),
      Offset(.641, .416), Offset(.650, .450), Offset(.632, .481),
      Offset(.607, .493), Offset(.583, .472), Offset(.567, .439),
    ],
    // Indian subcontinent.
    [
      Offset(.659, .393), Offset(.682, .401), Offset(.699, .429),
      Offset(.704, .465), Offset(.696, .502), Offset(.680, .541),
      Offset(.665, .520), Offset(.653, .482), Offset(.646, .445),
    ],
    // Japan.
    [
      Offset(.866, .383), Offset(.879, .390), Offset(.884, .410),
      Offset(.878, .431), Offset(.867, .449), Offset(.858, .438),
      Offset(.861, .415),
    ],
    // Sumatra.
    [
      Offset(.731, .622), Offset(.745, .611), Offset(.757, .624),
      Offset(.758, .649), Offset(.746, .678), Offset(.734, .670),
      Offset(.727, .645),
    ],
    // Borneo.
    [
      Offset(.765, .637), Offset(.786, .625), Offset(.806, .638),
      Offset(.813, .660), Offset(.804, .682), Offset(.783, .689),
      Offset(.766, .672), Offset(.758, .652),
    ],
    // Java.
    [
      Offset(.755, .699), Offset(.778, .694), Offset(.802, .699),
      Offset(.823, .706), Offset(.817, .716), Offset(.790, .713),
      Offset(.768, .710),
    ],
    // Sulawesi.
    [
      Offset(.829, .680), Offset(.839, .665), Offset(.850, .671),
      Offset(.851, .692), Offset(.865, .704), Offset(.855, .717),
      Offset(.842, .701), Offset(.830, .699), Offset(.820, .688),
    ],
    // Papua.
    [
      Offset(.868, .681), Offset(.892, .669), Offset(.917, .675),
      Offset(.937, .690), Offset(.932, .711), Offset(.908, .720),
      Offset(.883, .713), Offset(.866, .700),
    ],
    // Australia.
    [
      Offset(.805, .775), Offset(.832, .752), Offset(.866, .744),
      Offset(.900, .751), Offset(.932, .774), Offset(.951, .808),
      Offset(.950, .846), Offset(.930, .877), Offset(.900, .897),
      Offset(.866, .907), Offset(.834, .893), Offset(.809, .867),
      Offset(.792, .831), Offset(.793, .800),
    ],
    // Greenland.
    [
      Offset(.294, .091), Offset(.320, .070), Offset(.351, .065),
      Offset(.379, .080), Offset(.390, .110), Offset(.379, .146),
      Offset(.357, .174), Offset(.327, .179), Offset(.304, .151),
    ],
    // Madagascar.
    [
      Offset(.532, .666), Offset(.544, .675), Offset(.548, .706),
      Offset(.539, .741), Offset(.529, .735), Offset(.526, .704),
    ],
    // New Zealand North and South Islands.
    [
      Offset(.955, .900), Offset(.963, .907), Offset(.960, .928),
      Offset(.950, .940), Offset(.946, .925),
    ],
    [
      Offset(.967, .934), Offset(.977, .940), Offset(.973, .960),
      Offset(.962, .970), Offset(.958, .954),
    ],
  ];

  static const List<(String, String)> _routes = [
    ('Los Angeles', 'New York'),
    ('New York', 'London'),
    ('London', 'Rotterdam'),
    ('Rotterdam', 'Dubai'),
    ('Dubai', 'Mumbai'),
    ('Mumbai', 'Singapore'),
    ('Singapore', 'Bangkok'),
    ('Singapore', 'Hong Kong'),
    ('Hong Kong', 'Tokyo'),
    ('Singapore', 'Jakarta'),
    ('Jakarta', 'Kuala Lumpur'),
    ('Jakarta', 'Pontianak'),
    ('Jakarta', 'Bandung'),
    ('Bandung', 'Sukabumi'),
    ('Bandung', 'Surabaya'),
    ('Surabaya', 'Makassar'),
    ('Makassar', 'Sydney'),
    ('New York', 'Sao Paulo'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (var i = 1; i < 24; i++) {
      final x = size.width * i / 24;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var i = 1; i < 12; i++) {
      final y = size.height * i / 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final landPaint = Paint()..color = _land;
    final coastPaint = Paint()
      ..color = _coast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeJoin = StrokeJoin.round;

    for (final points in _landmasses) {
      final path = _smoothClosedPath(points, size);
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, coastPaint);
    }

    final citiesByName = {
      for (final city in CityCatalog.allCities) city.name: city,
    };
    final routePaint = Paint()
      ..color = const Color(0xFF29414D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final route in _routes) {
      final origin = citiesByName[route.$1];
      final destination = citiesByName[route.$2];
      if (origin == null || destination == null) continue;
      canvas.drawLine(
        Offset(origin.mapX * size.width, origin.mapY * size.height),
        Offset(destination.mapX * size.width, destination.mapY * size.height),
        routePaint,
      );
    }
  }

  Path _smoothClosedPath(List<Offset> points, Size size) {
    final scaled = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final path = Path()..moveTo(scaled.first.dx, scaled.first.dy);
    for (var i = 1; i < scaled.length; i++) {
      final current = scaled[i];
      final next = scaled[(i + 1) % scaled.length];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) => false;
}
