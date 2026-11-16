import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../models/city.dart';
import '../theme/app_theme.dart';
import '../widgets/hexagon_logo.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});
  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _icon = 'truck';
  String _city = 'jakarta';
  int _color = 0xFF2EE59D;
  bool _busy = false;
  String? _error;
  static const colors = [0xFF2EE59D,0xFF38BDF8,0xFFF59E0B,0xFFA78BFA,0xFFFB7185,0xFFE2E8F0];

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy=true; _error=null; });
    try {
      await context.read<AppState>().createCompany(
        name: _name.text.trim().isEmpty ? 'ADIEXPRESS' : _name.text.trim(),
        headquartersCityId: _city, logoId: _icon, logoColor: _color,
      );
    } catch (e) { if (mounted) setState(() => _error=e.toString()); }
    finally { if (mounted) setState(() => _busy=false); }
  }

  @override
  Widget build(BuildContext context) {
    final city = CityCatalog.findById(_city)!;
    final preview = _name.text.trim().isEmpty ? 'ADIEXPRESS' : _name.text.trim();
    return Scaffold(body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('ADI CORPORATION  /  GLOBAL LOGISTICS',style: TextStyle(color: AppColors.emerald,fontWeight: FontWeight.w900,letterSpacing:1)),
        const SizedBox(height:26),
        const Text('DIRIKAN PERUSAHAAN',style: TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
        const SizedBox(height:8),
        const Text('Bangun jaringan logistik globalmu. Tentukan nama, identitas, dan kota markas awal.',style:TextStyle(color:AppColors.textSecondary,height:1.5)),
        const SizedBox(height:20),
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[Color(0xFF1B3737),Color(0xFF17212A)]),
          borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.border)),
          child:Column(children:[
            HexagonLogo(iconId:_icon,accentColor:Color(_color),size:88),
            const SizedBox(height:12),
            Text(preview.toUpperCase(),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18),textAlign:TextAlign.center),
            Text(city.name+' • Calon markas perusahaan',style:const TextStyle(color:AppColors.textSecondary,fontSize:11)),
          ]),
        ),
        const SizedBox(height:18),
        Form(key:_formKey,child:TextFormField(
          controller:_name,maxLength:28,textCapitalization:TextCapitalization.words,
          onChanged:(_) => setState((){}),
          decoration:const InputDecoration(labelText:'Nama perusahaan',hintText:'ADIEXPRESS',prefixIcon:Icon(Icons.edit_business)),
          validator:(v)=>v!=null && v.trim().isNotEmpty && v.trim().length<3 ? 'Minimal 3 karakter.' : null,
        )),
        const SizedBox(height:12),
        const Text('PILIH IKON LOGO',style:TextStyle(color:AppColors.textSecondary,fontSize:10,fontWeight:FontWeight.w800)),
        const SizedBox(height:9),
        Wrap(spacing:9,children:HexagonLogo.iconOptions.entries.map((e)=>InkWell(
          onTap:()=>setState(()=>_icon=e.key),
          child:Container(width:49,height:49,decoration:BoxDecoration(
            color:_icon==e.key?Color(_color).withValues(alpha:.15):AppColors.surface,
            border:Border.all(color:_icon==e.key?Color(_color):AppColors.border),borderRadius:BorderRadius.circular(12)),
            child:Icon(e.value,color:_icon==e.key?Color(_color):AppColors.textSecondary)),
        )).toList()),
        const SizedBox(height:18),
        const Text('WARNA AKSEN',style:TextStyle(color:AppColors.textSecondary,fontSize:10,fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        Wrap(spacing:13,children:colors.map((c)=>GestureDetector(
          onTap:()=>setState(()=>_color=c),
          child:Container(width:34,height:34,decoration:BoxDecoration(
            color:Color(c),shape:BoxShape.circle,border:Border.all(color:_color==c?Colors.white:Colors.transparent,width:3)),
            child:_color==c?const Icon(Icons.check,size:16,color:AppColors.background):null),
        )).toList()),
        const SizedBox(height:20),
        const Text('PILIH KOTA MARKAS AWAL',style:TextStyle(color:AppColors.textSecondary,fontSize:10,fontWeight:FontWeight.w800)),
        const SizedBox(height:9),
        DropdownButtonFormField<String>(
          value:_city,isExpanded:true,decoration:const InputDecoration(prefixIcon:Icon(Icons.location_city)),
          items:CityCatalog.starterCities.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name+' • '+c.countryName,overflow:TextOverflow.ellipsis))).toList(),
          onChanged:(v){if(v!=null)setState(()=>_city=v);},
        ),
        const SizedBox(height:6),
        Text(city.region+'  •  '+city.countryCode,style:const TextStyle(color:AppColors.textSecondary,fontSize:11)),
        if(_error!=null) Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:AppColors.danger))),
        const SizedBox(height:22),
        SizedBox(height:52,child:FilledButton.icon(
          onPressed:_busy?null:_create,
          icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.rocket_launch),
          label:Text(_busy?'MENYIAPKAN...':'DIRIKAN PERUSAHAAN'),
          style:FilledButton.styleFrom(backgroundColor:AppColors.emerald,foregroundColor:AppColors.background),
        )),
        const SizedBox(height:12),
        const Text('MODAL AWAL  $50.000  •  1 LIGHT DELIVERY VAN',textAlign:TextAlign.center,style:TextStyle(color:AppColors.textSecondary,fontSize:10)),
      ],
    )));
  }
}
