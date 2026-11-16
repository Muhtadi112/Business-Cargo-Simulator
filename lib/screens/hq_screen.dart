import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/formatters.dart';
import '../models/city.dart';
import '../models/company.dart';
import '../models/contract.dart';
import '../models/fuel_system.dart';
import '../models/research.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_logo.dart';
import '../widgets/metric_card.dart';

class HqScreen extends StatefulWidget{const HqScreen({super.key});@override State<HqScreen> createState()=>_HqScreenState();}
class _HqScreenState extends State<HqScreen>{
 int tab=0;
 Timer? _clock;
 DateTime _nowUtc=DateTime.now().toUtc();
 @override void initState(){super.initState();_clock=Timer.periodic(const Duration(seconds:1),(_)=>setState(()=>_nowUtc=DateTime.now().toUtc()));}
 @override void dispose(){_clock?.cancel();super.dispose();}
 String countdown(DateTime end){final d=end.difference(_nowUtc);if(d.isNegative)return '00:00:00';final h=d.inHours.toString().padLeft(2,'0');final m=d.inMinutes.remainder(60).toString().padLeft(2,'0');final s=d.inSeconds.remainder(60).toString().padLeft(2,'0');return '$h:$m:$s';}
 DateTime get weekEnd {final d=DateTime.utc(_nowUtc.year,_nowUtc.month,_nowUtc.day);final monday=d.subtract(Duration(days:d.weekday-1));return monday.add(const Duration(days:7));}String _networkQuery='';String _networkRegion='Semua';static const labels=['Ringkasan','Jaringan','Riset','Target','Catatan perubahan'];
 String rep(int n)=>n>=9000?'Legenda Logistik':n>=6000?'Tycoon Global':n>=3000?'Mitra Elite':n>=1000?'Operator Berkembang':'Pendatang Baru';
 Future<void> edit()async{
  final s=context.read<AppState>();final c=s.company;if(c==null)return;final name=TextEditingController(text:c.name);var icon=c.logoId;var color=c.logoColor;
  const palette=[0xFF2EE59D,0xFF38BDF8,0xFFF59E0B,0xFFA78BFA,0xFFFB7185,0xFFE2E8F0];
  await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppColors.surface,builder:(sheet)=>StatefulBuilder(builder:(ctx,set)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Text('EDIT IDENTITAS PERUSAHAAN',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:14),Center(child:HexagonLogo(iconId:icon,accentColor:Color(color),size:78)),TextField(controller:name,maxLength:28,decoration:const InputDecoration(labelText:'Nama perusahaan')),
   Wrap(spacing:7,children:HexagonLogo.iconOptions.entries.map((e)=>IconButton(onPressed:()=>set(()=>icon=e.key),icon:Icon(e.value),color:icon==e.key?Color(color):AppColors.textSecondary)).toList()),
   Wrap(spacing:12,children:palette.map((v)=>GestureDetector(onTap:()=>set(()=>color=v),child:Container(width:30,height:30,decoration:BoxDecoration(color:Color(v),shape:BoxShape.circle,border:Border.all(color:color==v?Colors.white:Colors.transparent,width:3))))).toList()),
   const SizedBox(height:18),FilledButton(onPressed:()async{try{await s.updateBranding(name:name.text.trim(),logoId:icon,logoColor:color);if (sheet.mounted) { Navigator.pop(sheet); }}catch(e){if (sheet.mounted) { ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(content:Text(e.toString()))); }}},child:const Text('SIMPAN IDENTITAS')),
  ])))));
  name.dispose();
 }
 void profile(){final c=context.read<AppState>().company;if(c==null)return;showDialog(context:context,builder:(ctx)=>AlertDialog(backgroundColor:AppColors.surface,title:const Text('PROFIL & TROFI'),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text('Markas: ${c.headquartersCity}'),Text('Level: ${c.level}'),Text('Reputasi: ${c.reputationScore} • ${c.reputationTitle}'),Text('Kontrak selesai: ${c.completedContracts}'),const SizedBox(height:10),achievement('Perusahaan berdiri',true),achievement('Pengiriman pertama',c.completedContracts>=1),achievement('10 pengiriman',c.completedContracts>=10),achievement('Jaringan 5 kota',c.unlockedCityIds.length>=5)]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('TUTUP'))]));}
 Widget achievement(String t,bool yes)=>Row(children:[Icon(yes?Icons.check_circle:Icons.lock_outline,size:16,color:yes?AppColors.emerald:AppColors.textSecondary),const SizedBox(width:7),Text(t)]);
 @override Widget build(BuildContext context){final s=context.watch<AppState>();final c=s.company;if(c==null)return const Center(child:CircularProgressIndicator());final next=c.level*500;final p=(c.xp/next).clamp(0.0,1.0).toDouble();return ListView(padding:const EdgeInsets.all(15),children:[
  Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF1B3737),Color(0xFF17212A)]),borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[HexagonLogo(iconId:c.logoId,accentColor:Color(c.logoColor),size:67),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.name.toUpperCase(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),Text('${c.headquartersCity} • Markas perusahaan',style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),const SizedBox(height:7),Wrap(spacing:5,children:[badge(c.reputationTitle,AppColors.gold),badge('LEVEL ${c.level}',AppColors.emerald)])]))]),
   Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:edit,icon:const Icon(Icons.edit,size:14),label:const Text('Edit logo'))),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:profile,style:FilledButton.styleFrom(backgroundColor:AppColors.emerald,foregroundColor:AppColors.background),child:const Text('PROFIL & TROFI'))),
   const SizedBox(height:14),Row(children:[const Expanded(child:Text('PENGALAMAN PERUSAHAAN',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800))),Text('${c.xp} / $next XP',style:const TextStyle(color:AppColors.emerald,fontSize:10))]),const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:p,minHeight:7,backgroundColor:AppColors.background,valueColor:const AlwaysStoppedAnimation(AppColors.emerald))),Text('${next-c.xp} XP lagi menuju level ${c.level+1}',style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),
  ])),
  const SizedBox(height:15),SizedBox(height:38,child:ListView(scrollDirection:Axis.horizontal,children:List.generate(labels.length,(i)=>Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(labels[i],maxLines:1,overflow:TextOverflow.ellipsis),selected:tab==i,onSelected:(_)=>setState(()=>tab=i),selectedColor:AppColors.emerald.withValues(alpha:.16),backgroundColor:AppColors.surface,side:BorderSide(color:tab==i?AppColors.emerald:AppColors.border),labelStyle:TextStyle(fontSize:10,color:tab==i?AppColors.emerald:AppColors.textSecondary)))))),
  const SizedBox(height:13),if(tab==0)overview(s,c),if(tab==1)network(s,c),if(tab==2)research(c.level,c),if(tab==3)targets(c.completedContracts,c.unlockedCityIds.length,c),if(tab==4)changes(c),
 ]);}
 Widget badge(String t,Color color)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:color.withValues(alpha:.13),borderRadius:BorderRadius.circular(6)),child:Text(t.toUpperCase(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:color,fontSize:8,fontWeight:FontWeight.w900)));
 Widget overview(AppState s,Company c){final active=s.contracts.where((x)=>x.status==ContractStatus.inTransit).fold<double>(0,(v,x)=>v+x.reward);return Column(children:[GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:1.25,children:[
  MetricCard(label:'Uang tersedia',value:GameFormatters.currency(c.balance),icon:Icons.account_balance_wallet),
  MetricCard(label:'Nilai perusahaan',value:GameFormatters.currency(c.fleetValue+c.balance),icon:Icons.business_center,iconColor:AppColors.info),
  MetricCard(label:'Total pendapatan',value:GameFormatters.currency(c.totalRevenue),icon:Icons.trending_up),
  MetricCard(label:'Kontrak selesai',value:AppFormatters.number(c.completedContracts),icon:Icons.task_alt,iconColor:AppColors.info),
  MetricCard(label:'Reputasi',value:'${c.reputation}/100',subtitle:rep(c.reputation),icon:Icons.military_tech,iconColor:AppColors.gold),
  MetricCard(label:'Bersih kontrak aktif',value:GameFormatters.currency(active),icon:Icons.local_shipping),
 ]),const SizedBox(height:12),_fuelSection(s,c),const SizedBox(height:10),_weeklyEventCard()]);}

 Widget network(AppState s,Company c){
  const regions=['Semua','Asia Tenggara','Asia Timur','Timur Tengah','Eropa','Amerika','Afrika','Oseania'];
  final filtered=CityCatalog.allCities.where((city){
   final q=_networkQuery.toLowerCase();
   final matches=q.isEmpty||city.name.toLowerCase().contains(q)||city.countryName.toLowerCase().contains(q)||(q=='jepang'&&city.countryCode=='JP');
   final region=_networkRegion=='Semua'||(_networkRegion=='Amerika'?city.region.startsWith('Amerika'):city.region==_networkRegion);
   return matches&&region;
  }).toList();
  return Column(children:[
   TextField(onChanged:(v)=>setState(()=>_networkQuery=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kota atau negara')),
   const SizedBox(height:8),
   SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:regions.map((r)=>Padding(padding:const EdgeInsets.only(right:5),child:ChoiceChip(label:Text(r,style:const TextStyle(fontSize:10)),selected:_networkRegion==r,onSelected:(_)=>setState(()=>_networkRegion=r)))).toList())),
   const SizedBox(height:10),
   ...filtered.map((city){
    final open=c.unlockedCityIds.contains(city.id);
    return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),
     decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:open?AppColors.emerald.withValues(alpha:.4):AppColors.border)),
     child:Row(children:[
      Icon(open?Icons.location_on:Icons.lock_outline,color:open?AppColors.emerald:AppColors.textSecondary),
      const SizedBox(width:9),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text(city.name,style:const TextStyle(fontWeight:FontWeight.w800)),
       Text('${city.countryName} • ${city.region} • Tier ${city.tier} • ${city.hasPort?'⚓ Port':''}${city.hasAirport?' ✈ Airport':''}',style:const TextStyle(color:AppColors.textSecondary,fontSize:9)),
      ])),
      if(open)const Text('TERBUKA',style:TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900))
      else TextButton(onPressed:()async{try{await s.unlockCity(city.id);}catch(e){if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}},child:Text(city.unlockCost==0?'BUKA GRATIS':GameFormatters.currency(city.unlockCost))),
     ]),
    );
   }),
   const SizedBox(height:12),_terminalNetwork(s,c),
  ]);
 }

 Widget card(IconData icon,String title,String detail,String tag)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:AppColors.border)),child:Row(children:[Icon(icon,color:AppColors.emerald),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),Text(detail,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.textSecondary,fontSize:10))])),Text(tag,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900))]));
 Widget research(int level,Company c){
  return Column(children:ResearchDefinition.all.map((definition){
   final current=c.researchLevel(definition.category.name);
   final maxed=current>=ResearchRules.maxLevel;
   final cost=ResearchRules.upgradeCost(definition.category,current);
   final percent=ResearchRules.effectPercent(definition.category,current);
   final icon=switch(definition.category){ResearchCategory.efficientEngines=>Icons.speed,ResearchCategory.loadingCrew=>Icons.inventory_2,ResearchCategory.fleetEngineering=>Icons.build_circle,ResearchCategory.crewTraining=>Icons.groups,ResearchCategory.keyClients=>Icons.handshake,ResearchCategory.dispatchSoftware=>Icons.memory};
   return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(icon,color:AppColors.emerald),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(definition.title,style:const TextStyle(fontWeight:FontWeight.w900)),Text(definition.description,style:const TextStyle(fontSize:10,color:AppColors.textSecondary))])),Text('$current/10',style:const TextStyle(color:AppColors.emerald,fontWeight:FontWeight.w900))]),
    const SizedBox(height:8),LinearProgressIndicator(value:current/10,minHeight:5,backgroundColor:AppColors.border,color:AppColors.emerald),
    const SizedBox(height:8),Row(children:[Expanded(child:Text('Efek aktif: ${percent.toStringAsFixed(1)}%',style:const TextStyle(fontSize:10,color:AppColors.textSecondary))),FilledButton(onPressed:maxed?null:()async{try{await context.read<AppState>().upgradeResearch(definition.category);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:Text(maxed?'MAKS': 'RISET • ${GameFormatters.currency(cost)}'))]),
   ]));
  }).toList());
 }
 Widget targets(int done,int cities,Company c) {
  final state=context.watch<AppState>();
  final dailyEnd=(c.dailyGoalStartedAtUtc??DateTime.utc(_nowUtc.year,_nowUtc.month,_nowUtc.day)).add(const Duration(hours:24));
  final weeklyEnd=(c.weeklyGoalStartedAtUtc??weekEnd.subtract(const Duration(days:7))).add(const Duration(days:7));
  return Column(children:[
   _goalCard(Icons.today,'Target harian','Selesaikan 3 pengantaran',c.dailyDeliveries,3,dailyEnd,2500,80),
   _goalCard(Icons.calendar_month,'Target mingguan','Selesaikan 20 pengantaran',c.weeklyDeliveries,20,weeklyEnd,25000,600),
   card(Icons.local_shipping,'Beli kendaraan kedua','${state.vehicles.length} / 2 kendaraan',state.vehicles.length>=2?'SELESAI':'AKTIF'),
   card(Icons.public,'Buka 2 kota jaringan logistik','${cities} / 2 kota terbuka',cities>=2?'SELESAI':'AKTIF'),
  ]);
 }
 Widget _goalCard(IconData icon,String title,String objective,int progress,int target,DateTime reset,double reward,int xp){
  final done=progress>=target;
  return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:done?AppColors.emerald:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Icon(icon,color:AppColors.emerald),const SizedBox(width:8),Expanded(child:Text(title,style:const TextStyle(fontWeight:FontWeight.w900))),Text(done?'SELESAI':'${progress}/${target}',style:const TextStyle(color:AppColors.emerald,fontWeight:FontWeight.w900,fontSize:10))]),
   Text(objective,style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),const SizedBox(height:7),LinearProgressIndicator(value:(progress/target).clamp(0.0,1.0),color:AppColors.emerald,backgroundColor:AppColors.border,minHeight:5),
   const SizedBox(height:7),Row(children:[Expanded(child:Text('Hadiah ${GameFormatters.currency(reward)} + $xp XP',style:const TextStyle(fontSize:10))),Text('Reset ${countdown(reset)}',style:const TextStyle(fontSize:10,color:AppColors.gold,fontWeight:FontWeight.w800))]),
  ]));
 }

 Widget _fuelSection(AppState s,Company c){
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Align(alignment:Alignment.centerLeft,child:Text('TANGKI BAHAN BAKAR MARKAS',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12))),
   const SizedBox(height:8),
   _tankCard(s,c,FuelType.diesel,'Tangki Solar','Untuk truk dan van darat',Icons.local_gas_station),
   _tankCard(s,c,FuelType.jetFuel,'Tangki Avtur / Jet Fuel','Untuk pesawat kargo • membutuhkan cabang bandara',Icons.flight),
  ]);
 }
 Widget _tankCard(AppState s,Company c,FuelType type,String title,String subtitle,IconData icon){
  final tank=c.fuelSystem.tank(type);final built=tank.isBuilt;
  return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Icon(icon,color:AppColors.emerald),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),Text(subtitle,style:const TextStyle(color:AppColors.textSecondary,fontSize:9))])),Text(built?'LVL ${tank.level}':'BELUM ADA',style:const TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900))]),
   const SizedBox(height:7),Text(built?'Stok ${tank.storedLiters.toStringAsFixed(0)} / ${tank.capacityLiters.toStringAsFixed(0)} L':'Bangun tangki pertama untuk menyimpan bahan bakar.',style:const TextStyle(fontSize:10,color:AppColors.textSecondary)),
   const SizedBox(height:7),SizedBox(width:double.infinity,child:FilledButton(onPressed:type==FuelType.jetFuel&&!c.airportBranchBuilt?null:()async{try{await s.upgradeFuelTank(type);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},child:Text('${built?'UPGRADE':'BANGUN'} • ${GameFormatters.currency(tank.nextUpgradeCost)}'))),
   if(built)Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()async{try{await s.purchaseFuel(type);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}},icon:const Icon(Icons.add_circle_outline,size:14),label:const Text('BELI 1.000 L'))),
  ]));
 }
 Widget _weeklyEventCard(){
  final weekStart=weekEnd.subtract(const Duration(days:7));
  return Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF49351A),Color(0xFF242A27)]),borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.gold.withValues(alpha:.5))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[const Icon(Icons.event_available,color:AppColors.gold),const SizedBox(width:8),const Expanded(child:Text('EVENT KARGO MINGGUAN',style:TextStyle(fontWeight:FontWeight.w900,fontSize:11))),Text(countdown(weekEnd),style:const TextStyle(color:AppColors.gold,fontWeight:FontWeight.w900,fontSize:11))]),
   const SizedBox(height:7),const Text('Minggu panen dan curah',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15)),const Text('Bonus bayaran +25% untuk kontrak kategori makanan (Food) yang diberangkatkan pada minggu UTC ini.',style:TextStyle(fontSize:10,color:AppColors.textSecondary)),
   const SizedBox(height:6),Text('Periode UTC: ${weekStart.toString().substring(0,10)} – ${weekEnd.subtract(const Duration(seconds:1)).toString().substring(0,10)}',style:const TextStyle(fontSize:9,color:AppColors.gold)),
  ]));
 }
 Widget _terminalNetwork(AppState s,Company c){
  return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   const Text('HIRARKI TERMINAL GLOBAL',style:TextStyle(fontWeight:FontWeight.w900,fontSize:12)),const SizedBox(height:8),
   _terminalCard(s,Icons.warehouse,'Depo Darat','Tingkat ${c.depotLevel}/5 • ${s.fleetSlots} slot armada • ${c.depotLevel*4} slot staf • Dispatcher ${c.depotLevel>=3?'1':'0'} • Manajer Armada ${c.depotLevel>=4?'1':'0'}',c.depotLevel>=5?'MAKS':'UPGRADE • ${GameFormatters.currency(90000*c.depotLevel)}',c.depotLevel<5,()=>s.upgradeDepot()),
   _terminalCard(s,Icons.waves,'Terminal Sungai','Level 12 • Investasi ${GameFormatters.currency(600000)} • +12 slot armada',c.riverTerminalBuilt?'DIBANGUN':'BANGUN • ${GameFormatters.currency(600000)}',!c.riverTerminalBuilt&&c.level>=12,()=>s.buildTerminal('river'),locked:!c.riverTerminalBuilt&&c.level<12),
   _terminalCard(s,Icons.flight,'Cabang Bandara','Level 20 • Investasi ${GameFormatters.currency(2250000)} • Membuka jalur udara dan tangki avtur',c.airportBranchBuilt?'DIBANGUN':'BANGUN • ${GameFormatters.currency(2250000)}',!c.airportBranchBuilt&&c.level>=20,()=>s.buildTerminal('airport'),locked:!c.airportBranchBuilt&&c.level<20),
   _terminalCard(s,Icons.directions_boat,'Pelabuhan Laut','Level 30 • Investasi ${GameFormatters.currency(9000000)} • Membuka jalur kapal kontainer',c.seaPortBuilt?'DIBANGUN':'BANGUN • ${GameFormatters.currency(9000000)}',!c.seaPortBuilt&&c.level>=30,()=>s.buildTerminal('seaport'),locked:!c.seaPortBuilt&&c.level<30),
  ]);
 }
 Widget _terminalCard(AppState s,IconData icon,String title,String detail,String action,bool enabled,Future<void> Function() onTap,{bool locked=false}){
  return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(12),border:Border.all(color:AppColors.border)),child:Row(children:[
   Icon(icon,color:locked?AppColors.textSecondary:AppColors.emerald),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),Text(detail,style:const TextStyle(color:AppColors.textSecondary,fontSize:9))])),
   const SizedBox(width:5),FilledButton(onPressed:enabled?()async{try{await onTap();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}:null,child:Text(locked?'LEVEL LOCK':action,style:const TextStyle(fontSize:8))),
  ]));
 }
 Widget changes(c)=>Column(children:[card(Icons.rocket_launch,'Perusahaan didirikan','Markas utama di ${c.headquartersCity}',AppFormatters.dateTime(c.createdAtUtc)),card(Icons.public,'Jaringan hub','${c.unlockedCityIds.length} kota terbuka','AKTIF'),card(Icons.assignment,'Riwayat kontrak','${c.completedContracts} pengiriman selesai','OPERASI')]);
}
