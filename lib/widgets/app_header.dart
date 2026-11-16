import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../app/formatters.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final s=context.watch<AppState>(); final c=s.company;
    if(c==null)return const SizedBox.shrink();
    return Container(padding:const EdgeInsets.fromLTRB(16,11,16,13),
      decoration:const BoxDecoration(color:AppColors.background,border:Border(bottom:BorderSide(color:AppColors.border))),
      child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(c.name.toUpperCase(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14,letterSpacing:.6)),
          const SizedBox(height:4),
          Text('TINGKAT ${c.level} • ${c.headquartersCity}',style:const TextStyle(color:AppColors.textSecondary,fontSize:10)),
        ])),
        const SizedBox(width:8),
        Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
          Text(GameFormatters.currency(c.balance),style:const TextStyle(color:AppColors.emerald,fontWeight:FontWeight.w900,fontSize:15)),
          Text('${s.totalVehicles} kendaraan • ${s.activeVehicles} di perjalanan',style:const TextStyle(color:AppColors.textSecondary,fontSize:9)),
        ]),
      ]),
    );
  }
}
