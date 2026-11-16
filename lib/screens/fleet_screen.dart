import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/formatters.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class FleetScreen extends StatefulWidget {
 const FleetScreen({super.key});
 @override State<FleetScreen> createState()=>_FleetScreenState();
}
class _FleetScreenState extends State<FleetScreen> {
 int tab=0; int modeFilter=0; String q='';
 @override Widget build(BuildContext context) {
  final s=context.watch<AppState>(); final all=s.vehicles;
  final vehicles=all.where((v)=>(modeFilter==0||v.mode.index==modeFilter-1)&&v.specifications.name.toLowerCase().contains(q.toLowerCase())).toList();
  final idle=all.where((v)=>v.status==VehicleStatus.idle).length;
  final alert=all.where((v)=>v.fuel<20||v.condition<55).length;
  return ListView(padding:const EdgeInsets.all(13),children:[
   Row(children:[Expanded(child:FilledButton(onPressed:()=>setState(()=>tab=0),child:Text('Armada • ${all.length}'))),const SizedBox(width:7),Expanded(child:OutlinedButton(onPressed:()=>setState(()=>tab=1),child:const Text('Trailer • 0')))]),
   const SizedBox(height:10),FilledButton.icon(onPressed:()=>_dealership(context,s),icon:const Icon(Icons.add),label:const Text('Beli Armada')),
   const SizedBox(height:10),GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:2.6,mainAxisSpacing:7,crossAxisSpacing:7,children:[_metric('Total Armada','${all.length}/${s.fleetSlots}'),_metric('Menganggur',idle.toString()),_metric('Dalam perjalanan',s.activeVehicles.toString()),_metric('Perlu perhatian',alert.toString())]),
   const SizedBox(height:12),
   if(tab==0)...[
    Wrap(spacing:6,runSpacing:6,children:[_filter('Semua',0),_filter('Darat 🚛',1),_filter('Laut 🚢',2),_filter('Udara ✈️',3)]),
    const SizedBox(height:10),TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari armada')),
    const SizedBox(height:10),if(vehicles.isEmpty)const Center(child:Padding(padding:EdgeInsets.all(20),child:Text('Belum ada armada pada filter ini.'))),
    ...vehicles.map((v)=>_vehicle(context,s,v)),
   ] else const Text('Belum ada trailer.',style:TextStyle(color:AppColors.textSecondary)),
  ]);
 }
 Widget _filter(String label,int value)=>ChoiceChip(label:Text(label),selected:modeFilter==value,onSelected:(_)=>setState(()=>modeFilter=value));
 Widget _metric(String a,String b)=>Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(11),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:AppColors.textSecondary,fontSize:9)),Text(b,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15))]));
 Widget _vehicle(BuildContext c,AppState s,Vehicle v) {
  final spec=v.specifications; final fuel=(v.fuel/spec.fuelCapacityLiters).clamp(0.0,1.0);
  final assigned=s.contracts.where((c)=>c.contractId==v.assignedContractId);
  final routeDestination=assigned.isEmpty?'tujuan':assigned.first.destinationCityName;
  final icon=switch(v.mode){TransportMode.road=>Icons.local_shipping,TransportMode.sea=>Icons.directions_boat,TransportMode.air=>Icons.flight};
  final location=switch(v.mode){TransportMode.road=>'Terminal gudang / depot',TransportMode.sea=>'Pelabuhan global',TransportMode.air=>'Bandara kargo global'};
  return Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Expanded(child:Text(spec.name,style:const TextStyle(fontWeight:FontWeight.w900))),Text(v.status==VehicleStatus.idle?'SIAP':'DALAM PERJALANAN',style:const TextStyle(color:AppColors.emerald,fontSize:8,fontWeight:FontWeight.w900))]),
   const SizedBox(height:8),Row(children:[Icon(icon,size:38,color:AppColors.emerald),const SizedBox(width:9),Expanded(child:Text('#${v.vehicleId.substring(0,4).toUpperCase()} • ${spec.cargoCapacityKg.toStringAsFixed(0)} kg\n${v.effectiveMaxSpeed.toStringAsFixed(0)} km/j • ${spec.mode.name.toUpperCase()}',style:const TextStyle(color:AppColors.textSecondary,fontSize:9))),IconButton(onPressed:()=>_service(c,s,v),icon:const Icon(Icons.build)),IconButton(onPressed:()=>s.setTab(1),icon:const Icon(Icons.my_location))]),
   _bar(spec.fuelLabel,fuel,'${v.fuel.toStringAsFixed(1)} / ${spec.fuelCapacityLiters.toStringAsFixed(0)} L'),_bar('Kondisi',v.condition/100,'${v.condition.toStringAsFixed(0)}%'),
   const Divider(),Row(children:[_info('OPERATOR','Kamu'),_info('TERMINAL',location),_info('NILAI JUAL',GameFormatters.currency(v.estimatedValue))]),
   const SizedBox(height:6),Text(v.status==VehicleStatus.enRoute?'Rute ke ${routeDestination} • ETA ${v.arrivalTimeUtc?.toLocal().toString().substring(0,16)??'-'}':'Standby di ${s.company?.headquartersCity??'Markas'}',style:const TextStyle(color:AppColors.textSecondary,fontSize:9)),
  ]));
 }
 Widget _bar(String label,double value,String text)=>Padding(padding:const EdgeInsets.only(top:7),child:Column(children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(color:AppColors.textSecondary,fontSize:9))),Text(text,style:const TextStyle(fontSize:9))]),LinearProgressIndicator(value:value.clamp(0.0,1.0),color:AppColors.emerald,backgroundColor:AppColors.border,minHeight:4)]));
 Widget _info(String a,String b)=>Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:AppColors.textSecondary,fontSize:8)),Text(b,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800))]));
 Future<void> _service(BuildContext c,AppState s,Vehicle v)async{try{await s.refuelAndRepairVehicle(v.vehicleId);}catch(e){s.showToast(e.toString());}}
 void _dealership(BuildContext c,AppState s)=>showModalBottomSheet(context:c,builder:(ctx)=>SafeArea(child:ListView(shrinkWrap:true,children:VehicleCatalog.catalog.map((e)=>ListTile(leading:Icon(switch(e.mode){TransportMode.road=>Icons.local_shipping,TransportMode.sea=>Icons.directions_boat,TransportMode.air=>Icons.flight}),title:Text(e.name),subtitle:Text('${e.cargoCapacityKg.toStringAsFixed(0)} kg • ${e.maxSpeedKmh.toStringAsFixed(0)} km/j'),trailing:Text(GameFormatters.currency(e.purchasePrice)),onTap:()async{Navigator.pop(ctx);try{await s.buyVehicle(e.tier);}catch(err){s.showToast(err.toString());}})).toList())));
}
