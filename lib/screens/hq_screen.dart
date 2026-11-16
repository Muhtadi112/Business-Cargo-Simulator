import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/formatters.dart';
import '../models/city.dart';
import '../models/contract.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_logo.dart';
import '../widgets/metric_card.dart';

class HqScreen extends StatefulWidget{const HqScreen({super.key});@override State<HqScreen> createState()=>_HqScreenState();}
class _HqScreenState extends State<HqScreen>{
 int tab=0;static const labels=['Ringkasan','Jaringan','Riset','Target','Catatan perubahan'];
 String rep(int n)=>n>=90?'Legenda Logistik':n>=75?'Mitra Tepercaya':n>=60?'Operator Andal':n>=40?'Pendatang Baru':'Perlu Pembenahan';
 Future<void> edit()async{
  final s=context.read<AppState>();final c=s.company!;final name=TextEditingController(text:c.name);var icon=c.logoId;var color=c.logoColor;
  const palette=[0xFF2EE59D,0xFF38BDF8,0xFFF59E0B,0xFFA78BFA,0xFFFB7185,0xFFE2E8F0];
  await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:AppColors.surface,builder:(sheet)=>StatefulBuilder(builder:(ctx,set)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Text('EDIT IDENTITAS PERUSAHAAN',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:14),Center(child:HexagonLogo(iconId:icon,accentColor:Color(color),size:78)),TextField(controller:name,maxLength:28,decoration:const InputDecoration(labelText:'Nama perusahaan')),
   Wrap(spacing:7,children:HexagonLogo.iconOptions.entries.map((e)=>IconButton(onPressed:()=>set(()=>icon=e.key),icon:Icon(e.value),color:icon==e.key?Color(color):AppColors.textSecondary)).toList()),
   Wrap(spacing:12,children:palette.map((v)=>GestureDetector(onTap:()=>set(()=>color=v),child:Container(width:30,height:30,decoration:BoxDecoration(color:Color(v),shape:BoxShape.circle,border:Border.all(color:color==v?Colors.white:Colors.transparent,width:3))))).toList()),
   const SizedBox(height:18),FilledButton(onPressed:()async{try{await s.updateBranding(name:name.text.trim(),logoId:icon,logoColor:color);if (sheet.mounted) { Navigator.pop(sheet); }}catch(e){if (sheet.mounted) { ScaffoldMessenger.of(sheet).showSnackBar(SnackBar(content:Text(e.toString()))); }}},child:const Text('SIMPAN IDENTITAS')),
  ])))));
  name.dispose();
 }
 void profile(){final c=context.read<AppState>().company!;showDialog(context:context,builder:(ctx)=>AlertDialog(backgroundColor:AppColors.surface,title:const Text('PROFIL & TROFI'),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text('Markas: ${c.headquartersCity}'),Text('Level: ${c.level}'),Text('Reputasi: ${c.reputation}/100'),Text('Kontrak selesai: ${c.completedContracts}'),const SizedBox(height:10),achievement('Perusahaan berdiri',true),achievement('Pengiriman pertama',c.completedContracts>=1),achievement('10 pengiriman',c.completedContracts>=10),achievement('Jaringan 5 kota',c.unlockedCityIds.length>=5)]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('TUTUP'))]));}
 Widget achievement(String t,bool yes)=>Row(children:[Icon(yes?Icons.check_circle:Icons.lock_outline,size:16,color:yes?AppColors.emerald:AppColors.textSecondary),const SizedBox(width:7),Text(t)]);
 @override Widget build(BuildContext context){final s=context.watch<AppState>();final c=s.company!;final next=c.level*500;final p=(c.xp/next).clamp(0.0,1.0).toDouble();return ListView(padding:const EdgeInsets.all(15),children:[
  Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF1B3737),Color(0xFF17212A)]),borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[HexagonLogo(iconId:c.logoId,accentColor:Color(c.logoColor),size:67),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.name.toUpperCase(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),Text('${c.headquartersCity} • Markas perusahaan',style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),const SizedBox(height:7),Wrap(spacing:5,children:[badge(rep(c.reputation),AppColors.gold),badge('LEVEL ${c.level}',AppColors.emerald)])]))]),
   Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:edit,icon:const Icon(Icons.edit,size:14),label:const Text('Edit logo'))),
   SizedBox(width:double.infinity,child:FilledButton(onPressed:profile,style:FilledButton.styleFrom(backgroundColor:AppColors.emerald,foregroundColor:AppColors.background),child:const Text('PROFIL & TROFI'))),
   const SizedBox(height:14),Row(children:[const Expanded(child:Text('PENGALAMAN PERUSAHAAN',style:TextStyle(fontSize:10,fontWeight:FontWeight.w800))),Text('${c.xp} / $next XP',style:const TextStyle(color:AppColors.emerald,fontSize:10))]),const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:p,minHeight:7,backgroundColor:AppColors.background,valueColor:const AlwaysStoppedAnimation(AppColors.emerald))),Text('${next-c.xp} XP lagi menuju level ${c.level+1}',style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),
  ])),
  const SizedBox(height:15),SizedBox(height:38,child:ListView(scrollDirection:Axis.horizontal,children:List.generate(labels.length,(i)=>Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(labels[i],maxLines:1,overflow:TextOverflow.ellipsis),selected:tab==i,onSelected:(_)=>setState(()=>tab=i),selectedColor:AppColors.emerald.withValues(alpha:.16),backgroundColor:AppColors.surface,side:BorderSide(color:tab==i?AppColors.emerald:AppColors.border),labelStyle:TextStyle(fontSize:10,color:tab==i?AppColors.emerald:AppColors.textSecondary)))))),
  const SizedBox(height:13),if(tab==0)overview(s),if(tab==1)network(s),if(tab==2)research(c.level),if(tab==3)targets(c.completedContracts,c.unlockedCityIds.length),if(tab==4)changes(c),
 ]);}
 Widget badge(String t,Color color)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:color.withValues(alpha:.13),borderRadius:BorderRadius.circular(6)),child:Text(t.toUpperCase(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:color,fontSize:8,fontWeight:FontWeight.w900)));
 Widget overview(AppState s){final c=s.company!;final active=s.contracts.where((x)=>x.status==ContractStatus.inTransit).fold<double>(0,(v,x)=>v+x.reward);return GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:1.25,children:[
  MetricCard(label:'Uang tersedia',value:AppFormatters.money(c.balance),icon:Icons.account_balance_wallet),
  MetricCard(label:'Nilai perusahaan',value:AppFormatters.money(c.fleetValue+c.balance),icon:Icons.business_center,iconColor:AppColors.info),
  MetricCard(label:'Total pendapatan',value:AppFormatters.money(c.totalRevenue),icon:Icons.trending_up),
  MetricCard(label:'Kontrak selesai',value:AppFormatters.number(c.completedContracts),icon:Icons.task_alt,iconColor:AppColors.info),
  MetricCard(label:'Reputasi',value:'${c.reputation}/100',subtitle:rep(c.reputation),icon:Icons.military_tech,iconColor:AppColors.gold),
  MetricCard(label:'Bersih kontrak aktif',value:AppFormatters.money(active),icon:Icons.local_shipping),
 ]);}
 Widget network(AppState s){final c=s.company!;return Column(children:CityCatalog.allCities.map((city){final open=c.unlockedCityIds.contains(city.id);return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:open?AppColors.emerald.withValues(alpha:.4):AppColors.border)),child:Row(children:[Icon(open?Icons.location_on:Icons.lock_outline,color:open?AppColors.emerald:AppColors.textSecondary),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(city.name,style:const TextStyle(fontWeight:FontWeight.w800)),Text('${city.countryName} • ${city.region}',style:const TextStyle(color:AppColors.textSecondary,fontSize:10))])),if(open)const Text('TERBUKA',style:TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900))else TextButton(onPressed:()async{try{await s.unlockCity(city.id);}catch(e){if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()))); }}},child:Text(city.unlockCost==0?'BUKA GRATIS':AppFormatters.money(city.unlockCost)))]));}).toList());}
 Widget card(IconData icon,String title,String detail,String tag)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:AppColors.border)),child:Row(children:[Icon(icon,color:AppColors.emerald),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),Text(detail,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.textSecondary,fontSize:10))])),Text(tag,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.emerald,fontSize:9,fontWeight:FontWeight.w900))]));
 Widget research(int level)=>Column(children:[card(Icons.alt_route,'Optimasi Rute','Efisiensi perjalanan dan estimasi waktu.',level>=2?'TERSEDIA':'LEVEL 2'),card(Icons.local_shipping,'Manajemen Armada','Peningkatan kapasitas operasional.',level>=4?'TERSEDIA':'LEVEL 4'),card(Icons.hub,'Pusat Distribusi','Perluas jaringan hub.',level>=7?'TERSEDIA':'LEVEL 7')]);
 Widget targets(int done,int cities) {
  final state = context.watch<AppState>();
  final company = state.company!;
  final vehicles = state.vehicles.length;
  final value = company.balance + company.fleetValue;
  return Column(children: [
    card(Icons.local_shipping, 'Beli kendaraan kedua', '$vehicles / 2 kendaraan', vehicles >= 2 ? 'SELESAI' : 'AKTIF'),
    card(Icons.assignment_turned_in, 'Selesaikan 3 kontrak pengiriman', '$done / 3 kontrak selesai', done >= 3 ? 'SELESAI' : 'AKTIF'),
    card(Icons.public, 'Buka 2 kota jaringan logistik', '$cities / 2 kota terbuka', cities >= 2 ? 'SELESAI' : 'AKTIF'),
    card(Icons.business, 'Capai nilai perusahaan \$100K', AppFormatters.money(value), value >= 100000 ? 'SELESAI' : 'AKTIF'),
  ]);
}
 Widget changes(c)=>Column(children:[card(Icons.rocket_launch,'Perusahaan didirikan','Markas utama di ${c.headquartersCity}',AppFormatters.dateTime(c.createdAtUtc)),card(Icons.public,'Jaringan hub','${c.unlockedCityIds.length} kota terbuka','AKTIF'),card(Icons.assignment,'Riwayat kontrak','${c.completedContracts} pengiriman selesai','OPERASI')]);
}
