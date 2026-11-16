import 'fuel_system.dart';

class Company {
  const Company({
    required this.id, required this.name, required this.headquartersCity, required this.countryCode,
    required this.logoId, required this.logoColor, required this.level, required this.xp, required this.reputation,
    required this.balance, required this.totalRevenue, required this.fleetValue, required this.completedContracts,
    required this.unlockedCityIds, required this.createdAtUtc,
    this.reputationScore = 50, this.fuelSystem = const FuelSystem(), this.depotLevel = 1,
    this.riverTerminalBuilt = false, this.airportBranchBuilt = false, this.seaPortBuilt = false,
    this.researchLevels = const <String,int>{}, this.dailyGoalStartedAtUtc, this.weeklyGoalStartedAtUtc,
    this.dailyDeliveries = 0, this.weeklyDeliveries = 0,
  });
  final String id, name, headquartersCity, countryCode, logoId;
  final int logoColor, level, xp, reputation, completedContracts, reputationScore, depotLevel;
  final double balance, totalRevenue, fleetValue;
  final List<String> unlockedCityIds;
  final DateTime createdAtUtc;
  final FuelSystem fuelSystem;
  final bool riverTerminalBuilt, airportBranchBuilt, seaPortBuilt;
  final Map<String,int> researchLevels;
  final DateTime? dailyGoalStartedAtUtc, weeklyGoalStartedAtUtc;
  final int dailyDeliveries, weeklyDeliveries;

  String get reputationTitle => reputationScore >= 9000 ? 'Legenda Logistik' : reputationScore >= 6000 ? 'Tycoon Global' : reputationScore >= 3000 ? 'Mitra Elite' : reputationScore >= 1000 ? 'Operator Berkembang' : 'Pendatang Baru';
  int researchLevel(String key) => researchLevels[key] ?? 0;

  factory Company.newCompany({required String id, required String name, String headquartersCity = 'Jakarta', String countryCode = 'ID', String logoId = 'local_shipping', int logoColor = 0xFF2EE59D, DateTime? createdAtUtc}) {
    final now = (createdAtUtc ?? DateTime.now()).toUtc();
    return Company(id:id,name:name.trim(),headquartersCity:headquartersCity,countryCode:countryCode,logoId:logoId,logoColor:logoColor,level:1,xp:0,reputation:50,reputationScore:50,balance:50000,totalRevenue:0,fleetValue:12000,completedContracts:0,unlockedCityIds:<String>[headquartersCity.toLowerCase().replaceAll(' ','_')],createdAtUtc:now,dailyGoalStartedAtUtc:DateTime.utc(now.year,now.month,now.day),weeklyGoalStartedAtUtc:_weekStart(now));
  }

  static DateTime _weekStart(DateTime value) {
    final utc=value.toUtc(); final day=DateTime.utc(utc.year,utc.month,utc.day);
    return day.subtract(Duration(days:day.weekday-1));
  }

  Company copyWith({
    String? id,String? name,String? headquartersCity,String? countryCode,String? logoId,int? logoColor,int? level,int? xp,int? reputation,
    double? balance,double? totalRevenue,double? fleetValue,int? completedContracts,List<String>? unlockedCityIds,DateTime? createdAtUtc,
    int? reputationScore,FuelSystem? fuelSystem,int? depotLevel,bool? riverTerminalBuilt,bool? airportBranchBuilt,bool? seaPortBuilt,
    Map<String,int>? researchLevels,DateTime? dailyGoalStartedAtUtc,bool clearDailyGoalStart=false,DateTime? weeklyGoalStartedAtUtc,bool clearWeeklyGoalStart=false,int? dailyDeliveries,int? weeklyDeliveries,
  }) => Company(
    id:id??this.id,name:name??this.name,headquartersCity:headquartersCity??this.headquartersCity,countryCode:countryCode??this.countryCode,logoId:logoId??this.logoId,logoColor:logoColor??this.logoColor,
    level:level??this.level,xp:xp??this.xp,reputation:reputation??this.reputation,reputationScore:reputationScore??this.reputationScore,balance:balance??this.balance,totalRevenue:totalRevenue??this.totalRevenue,
    fleetValue:fleetValue??this.fleetValue,completedContracts:completedContracts??this.completedContracts,unlockedCityIds:List<String>.of(unlockedCityIds??this.unlockedCityIds),createdAtUtc:createdAtUtc??this.createdAtUtc,
    fuelSystem:fuelSystem??this.fuelSystem,depotLevel:depotLevel??this.depotLevel,riverTerminalBuilt:riverTerminalBuilt??this.riverTerminalBuilt,airportBranchBuilt:airportBranchBuilt??this.airportBranchBuilt,seaPortBuilt:seaPortBuilt??this.seaPortBuilt,
    researchLevels:Map<String,int>.of(researchLevels??this.researchLevels),dailyGoalStartedAtUtc:clearDailyGoalStart?null:dailyGoalStartedAtUtc??this.dailyGoalStartedAtUtc,weeklyGoalStartedAtUtc:clearWeeklyGoalStart?null:weeklyGoalStartedAtUtc??this.weeklyGoalStartedAtUtc,dailyDeliveries:dailyDeliveries??this.dailyDeliveries,weeklyDeliveries:weeklyDeliveries??this.weeklyDeliveries,
  );

  Map<String,dynamic> toJson()=>{'id':id,'name':name,'headquartersCity':headquartersCity,'countryCode':countryCode,'logoId':logoId,'logoColor':logoColor,'level':level,'xp':xp,'reputation':reputation,'reputationScore':reputationScore,'balance':balance,'totalRevenue':totalRevenue,'fleetValue':fleetValue,'completedContracts':completedContracts,'unlockedCityIds':unlockedCityIds,'createdAtUtc':createdAtUtc.toUtc().toIso8601String(),'fuelSystem':fuelSystem.toJson(),'depotLevel':depotLevel,'riverTerminalBuilt':riverTerminalBuilt,'airportBranchBuilt':airportBranchBuilt,'seaPortBuilt':seaPortBuilt,'researchLevels':researchLevels,'dailyGoalStartedAtUtc':dailyGoalStartedAtUtc?.toUtc().toIso8601String(),'weeklyGoalStartedAtUtc':weeklyGoalStartedAtUtc?.toUtc().toIso8601String(),'dailyDeliveries':dailyDeliveries,'weeklyDeliveries':weeklyDeliveries};

  factory Company.fromJson(Map<String,dynamic> json)=>Company(
    id:json['id'] as String,name:json['name'] as String,headquartersCity:json['headquartersCity'] as String? ?? 'Jakarta',countryCode:json['countryCode'] as String? ?? 'ID',logoId:json['logoId'] as String? ?? 'local_shipping',logoColor:(json['logoColor'] as num?)?.toInt()??0xFF2EE59D,
    level:(json['level'] as num?)?.toInt()??1,xp:(json['xp'] as num?)?.toInt()??0,reputation:(json['reputation'] as num?)?.toInt()??50,reputationScore:(json['reputationScore'] as num?)?.toInt()??(json['reputation'] as num?)?.toInt()??50,
    balance:(json['balance'] as num?)?.toDouble()??50000,totalRevenue:(json['totalRevenue'] as num?)?.toDouble()??0,fleetValue:(json['fleetValue'] as num?)?.toDouble()??0,completedContracts:(json['completedContracts'] as num?)?.toInt()??0,
    unlockedCityIds:List<String>.from((json['unlockedCityIds'] as List<dynamic>?)??const <String>[]),createdAtUtc:DateTime.parse(json['createdAtUtc'] as String).toUtc(),
    fuelSystem:FuelSystem.fromJson(json['fuelSystem'] as Map<String,dynamic>?),depotLevel:(json['depotLevel'] as num?)?.toInt()??1,riverTerminalBuilt:json['riverTerminalBuilt'] as bool? ?? false,airportBranchBuilt:json['airportBranchBuilt'] as bool? ?? false,seaPortBuilt:json['seaPortBuilt'] as bool? ?? false,
    researchLevels:Map<String,int>.from((json['researchLevels'] as Map<String,dynamic>?)?.map((k,v)=>MapEntry(k,(v as num).toInt()))??const <String,int>{}),
    dailyGoalStartedAtUtc:json['dailyGoalStartedAtUtc']==null?null:DateTime.parse(json['dailyGoalStartedAtUtc'] as String).toUtc(),weeklyGoalStartedAtUtc:json['weeklyGoalStartedAtUtc']==null?null:DateTime.parse(json['weeklyGoalStartedAtUtc'] as String).toUtc(),dailyDeliveries:(json['dailyDeliveries'] as num?)?.toInt()??0,weeklyDeliveries:(json['weeklyDeliveries'] as num?)?.toInt()??0,
  );
}
