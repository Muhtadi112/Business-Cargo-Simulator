import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../models/city.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
}
class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final AnimationController anim = AnimationController(vsync:this,duration:const Duration(seconds:16))..repeat();
  @override void dispose(){anim.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final s=context.watch<AppState>(); final c=s.company;
    final missions=[
      _Mission('Beli kendaraan kedua',s.vehicles.length,2),
      _Mission('Selesaikan 3 kontrak pengiriman',c?.completedContracts??0,3),
      _Mission('Buka 2 kota jaringan logistik',c?.unlockedCityIds.length??0,2),
      _Mission('Capai nilai perusahaan \$100K',(c?.balance??0)+(c?.fleetValue??0),100000),
    ];
    final index=missions.indexWhere((m)=>!m.done);
    final mission=missions[index<0?missions.length-1:index];
    return Stack(children:[
      Positioned.fill(child:InteractiveViewer(minScale:.6,maxScale:4,boundaryMargin:const EdgeInsets.all(200),child:SizedBox(width:1000,height:700,child:AnimatedBuilder(animation:anim,builder:(context,_)=>CustomPaint(painter:_WorldPainter(s.activeVehicles,anim.value)))))),
      Positioned(left:12,right:12,top:12,child:Row(children:[_chip(Icons.notifications_none,'2'),const Spacer(),_chip(Icons.ac_unit,'Musim dingin • sisa 26m 25s')])),
      Positioned(left:12,right:12,bottom:12,child:Column(children:[
        Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(15),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(index<0?'SEMUA TARGET AWAL SELESAI':'TARGET BERIKUTNYA • ${index+1} DARI ${missions.length}',style:const TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text(index<0?'Lanjutkan ekspansi perusahaan':'${mission.title} • ${mission.currentLabel} / ${mission.targetLabel}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(height:8),LinearProgressIndicator(value:mission.progress,color:AppColors.emerald,backgroundColor:AppColors.border),
        ])),
        const SizedBox(height:10),Row(children:[_chip(Icons.sports_esports,'Mengemudi'),const SizedBox(width:7),_chip(Icons.music_note,'Musik'),const Spacer(),_chip(Icons.emoji_events,'3')]),
      ])),
    ]);
  }
}
class _Mission {
  const _Mission(this.title,this.current,this.target);
  final String title; final num current,target;
  bool get done=>current>=target;
  double get progress=>(current/target).clamp(0.0,1.0).toDouble();
  String get currentLabel=>_label(current);
  String get targetLabel=>_label(target);
  String _label(num n)=>n>=1000?'${(n/1000).toStringAsFixed(0)}K':n.toStringAsFixed(0);
}
Widget _chip(IconData icon,String text)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:10),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:AppColors.border)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:16,color:AppColors.emerald),const SizedBox(width:6),Text(text,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800))]));

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.active,this.progress);
  final int active; final double progress;
  static const land=Color(0xFF132029),coast=Color(0xFF223542),grid=Color(0xFF111B22);
  static const shapes=<List<Offset>>[
    [Offset(.05,.20),Offset(.09,.13),Offset(.16,.10),Offset(.22,.13),Offset(.28,.20),Offset(.29,.26),Offset(.25,.31),Offset(.22,.38),Offset(.18,.40),Offset(.14,.35),Offset(.09,.32),Offset(.06,.26)],
    [Offset(.22,.42),Offset(.27,.43),Offset(.30,.50),Offset(.31,.57),Offset(.28,.68),Offset(.25,.80),Offset(.22,.87),Offset(.19,.79),Offset(.18,.68),Offset(.17,.57),Offset(.19,.48)],
    [Offset(.42,.20),Offset(.46,.17),Offset(.51,.18),Offset(.55,.22),Offset(.54,.27),Offset(.50,.30),Offset(.46,.28),Offset(.43,.25)],
    [Offset(.44,.32),Offset(.50,.31),Offset(.56,.35),Offset(.57,.43),Offset(.55,.53),Offset(.52,.63),Offset(.49,.70),Offset(.46,.65),Offset(.43,.54),Offset(.42,.43)],
    [Offset(.53,.18),Offset(.61,.12),Offset(.71,.11),Offset(.81,.14),Offset(.90,.18),Offset(.96,.24),Offset(.96,.31),Offset(.91,.37),Offset(.85,.38),Offset(.80,.35),Offset(.75,.40),Offset(.70,.38),Offset(.66,.42),Offset(.61,.38),Offset(.57,.32),Offset(.54,.26)],
    [Offset(.57,.39),Offset(.62,.40),Offset(.65,.46),Offset(.63,.52),Offset(.60,.54),Offset(.57,.48)],
    [Offset(.67,.40),Offset(.70,.44),Offset(.71,.50),Offset(.69,.57),Offset(.67,.52),Offset(.65,.45)],
    [Offset(.87,.39),Offset(.90,.41),Offset(.89,.45),Offset(.87,.47),Offset(.86,.43)],
    [Offset(.72,.60),Offset(.77,.59),Offset(.82,.62),Offset(.85,.65),Offset(.82,.67),Offset(.78,.66),Offset(.74,.64)],
    [Offset(.75,.68),Offset(.79,.68),Offset(.83,.70),Offset(.84,.72),Offset(.81,.73),Offset(.77,.72)],
    [Offset(.84,.70),Offset(.87,.69),Offset(.89,.71),Offset(.88,.73),Offset(.85,.73)],
    [Offset(.81,.78),Offset(.87,.75),Offset(.93,.78),Offset(.95,.83),Offset(.92,.89),Offset(.86,.91),Offset(.81,.87),Offset(.79,.82)],
    [Offset(.31,.09),Offset(.36,.07),Offset(.39,.11),Offset(.37,.18),Offset(.33,.20),Offset(.30,.15)],
  ];
  static const local=<String,Offset>{
    'Sukabumi':Offset(.787,.705),'Bandung':Offset(.792,.700),'Surabaya':Offset(.817,.706),
    'Jambi':Offset(.766,.670),'Pontianak':Offset(.775,.660),'Makassar':Offset(.837,.710),
  };
  static const hubs=<String,Offset>{
    'Los Angeles':Offset(.155,.355),'New York':Offset(.255,.285),'Sao Paulo':Offset(.255,.690),
    'London':Offset(.475,.235),'Rotterdam':Offset(.490,.245),'Dubai':Offset(.610,.445),
    'Mumbai':Offset(.680,.490),'Singapore':Offset(.795,.685),'Bangkok':Offset(.770,.625),
    'Hong Kong':Offset(.835,.555),'Shanghai':Offset(.855,.420),'Seoul':Offset(.875,.395),
    'Tokyo':Offset(.895,.425),'Sydney':Offset(.900,.830),
  };
  @override void paint(Canvas canvas,Size size) {
    canvas.drawRect(Offset.zero&size,Paint()..color=AppColors.background);
    final gp=Paint()..color=grid..strokeWidth=1;
    for(var i=1;i<12;i++){final x=size.width*i/12;canvas.drawLine(Offset(x,0),Offset(x,size.height),gp);}
    for(var i=1;i<8;i++){final y=size.height*i/8;canvas.drawLine(Offset(0,y),Offset(size.width,y),gp);}
    final fp=Paint()..color=land,sp=Paint()..color=coast..style=PaintingStyle.stroke..strokeWidth=1.4..strokeJoin=StrokeJoin.round;
    for(final polygon in shapes){final path=Path()..moveTo(polygon.first.dx*size.width,polygon.first.dy*size.height);for(final p in polygon.skip(1)){path.lineTo(p.dx*size.width,p.dy*size.height);}path.close();canvas.drawPath(path,fp);canvas.drawPath(path,sp);}
    Offset at(Offset p)=>Offset(p.dx*size.width,p.dy*size.height);
    final points=<String,Offset>{...hubs,...local,'Jakarta':const Offset(.783,.692)};
    const routes=[
      ('Los Angeles','New York'),('New York','London'),('London','Rotterdam'),('Rotterdam','Dubai'),('Dubai','Mumbai'),('Mumbai','Singapore'),('Singapore','Bangkok'),('Singapore','Jakarta'),('Jakarta','Pontianak'),('Jakarta','Jambi'),('Jakarta','Bandung'),('Bandung','Sukabumi'),('Bandung','Surabaya'),('Surabaya','Makassar'),('Singapore','Hong Kong'),('Hong Kong','Shanghai'),('Shanghai','Seoul'),('Seoul','Tokyo'),('Singapore','Sydney'),
    ];
    final rp=Paint()..color=const Color(0xFF29414D)..strokeWidth=1.5;
    for(final r in routes){canvas.drawLine(at(points[r.$1]!),at(points[r.$2]!),rp);}
    final cities=CityCatalog.allCities,coords=cities.map((c)=>Offset(c.mapX,c.mapY)).toList();
    for(var i=0;i<coords.length-1;i++){canvas.drawLine(at(coords[i]),at(coords[i+1]),rp);}
    if(coords.length>1){final a=at(coords[0]),b=at(coords[1]);canvas.drawLine(a,b,Paint()..color=AppColors.emerald..strokeWidth=2.5);canvas.drawCircle(Offset(a.dx+(b.dx-a.dx)*progress,a.dy+(b.dy-a.dy)*progress),6,Paint()..color=AppColors.emerald);}
    void drawCity(String name,Offset p,bool major){final pos=at(p);canvas.drawCircle(pos,major?5:3,Paint()..color=major?AppColors.gold:AppColors.textSecondary);final label=TextPainter(text:TextSpan(text:name,style:TextStyle(color:major?AppColors.textPrimary:AppColors.textSecondary,fontSize:major?10:8,fontWeight:major?FontWeight.w800:FontWeight.w500)),textDirection:TextDirection.ltr)..layout(maxWidth:105);label.paint(canvas,pos.translate(6,-label.height/2));}
    for(final e in hubs.entries){drawCity(e.key,e.value,false);}
    for(final e in local.entries){drawCity(e.key,e.value,true);}
    drawCity('Jakarta',const Offset(.783,.692),true);
    for(final city in cities){drawCity(city.name,Offset(city.mapX,city.mapY),city.name=='Jakarta');}
  }
  @override bool shouldRepaint(covariant _WorldPainter old)=>old.progress!=progress||old.active!=active;
}
