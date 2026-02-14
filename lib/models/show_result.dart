import 'package:hive/hive.dart';

part 'show_result.g.dart';

@HiveType(typeId: 23)
class ShowResult extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String dogId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late String showName; // f.eks. "NKK Drammen", "Sandefjord Hundeklubb"

  @HiveField(4)
  String? judge; // Dommernavn

  @HiveField(5)
  late String showClass; // 'Valp', 'Junior', 'Bruks', 'Åpen', 'Champion', 'Veteran'

  @HiveField(6)
  late String quality; // 'Excellent', 'Very Good', 'Good', 'Sufficient', 'Disqualified', 'Cannot be judged'

  @HiveField(7)
  String? placement; // 'CK', 'BIR', 'BIM', '2BHK', '3BHK', '4BHK', null

  @HiveField(8)
  List<String>? certificates; // Liste av sertifikater: 'CERT', 'CACIB', 'CAC', 'resCAC', 'resCACIB'

  @HiveField(9)
  String? groupResult; // 'BIG1', 'BIG2', 'BIG3', 'BIG4', null (kun hvis BIR)

  @HiveField(10)
  String? bisResult; // 'BIS1', 'BIS2', 'BIS3', 'BIS4', null (kun hvis BIG1)

  @HiveField(11)
  String? critique; // Dommerkritikk

  @HiveField(12)
  String? notes; // Egne notater

  @HiveField(13)
  String? showType; // 'Nasjonal', 'Internasjonal', 'Klubbutstilling', 'Rasespesial'

  @HiveField(14, defaultValue: false)
  bool hasCK = false; // CK (Certifikat Kvalitet) - kun mulig med Excellent

  @HiveField(15)
  String? classPlacement; // Plassering i klassen: 1, 2, 3, 4, Uplassert

  @HiveField(16)
  String? bestOfSexPlacement; // Plassering i beste hannhund/tispe: 1, 2, 3, 4

  @HiveField(17)
  String? groupJudge; // Gruppedommer

  @HiveField(18)
  String? bisJudge; // BIS-dommer

  ShowResult({
    required this.id,
    required this.dogId,
    required this.date,
    required this.showName,
    this.judge,
    required this.showClass,
    required this.quality,
    this.placement,
    this.certificates,
    this.groupResult,
    this.bisResult,
    this.critique,
    this.notes,
    this.showType,
    this.hasCK = false,
    this.classPlacement,
    this.bestOfSexPlacement,
    this.groupJudge,
    this.bisJudge,
  });

  /// Sjekk om hunden ble BIR (kvalifisert for gruppefinale)
  bool get isBIR => placement == 'BIR';

  /// Sjekk om hunden vant gruppen (kvalifisert for BIS)
  bool get isBIG1 => groupResult == 'BIG1';

  /// Sjekk om hunden fikk CK (brukes i statistikk)
  /// CK kan også være implisitt gitt via BIR/BIM
  bool get gotCK => hasCK || placement == 'BIR' || placement == 'BIM';

  /// Returnerer en formatert streng av resultatet
  String getResultSummary() {
    final parts = <String>[];
    
    if (quality.isNotEmpty) parts.add(quality);
    if (placement != null) parts.add(placement!);
    if (certificates != null && certificates!.isNotEmpty) parts.addAll(certificates!);
    if (groupResult != null) parts.add(groupResult!);
    if (bisResult != null) parts.add(bisResult!);
    
    return parts.join(', ');
  }

  /// Serialize ShowResult to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dogId': dogId,
      'date': date.toIso8601String(),
      'showName': showName,
      'judge': judge,
      'showClass': showClass,
      'quality': quality,
      'placement': placement,
      'certificates': certificates,
      'groupResult': groupResult,
      'bisResult': bisResult,
      'critique': critique,
      'notes': notes,
      'showType': showType,
      'hasCK': hasCK,
      'classPlacement': classPlacement,
      'bestOfSexPlacement': bestOfSexPlacement,
      'groupJudge': groupJudge,
      'bisJudge': bisJudge,
    };
  }

  /// Deserialize ShowResult from Firebase JSON
  factory ShowResult.fromJson(Map<String, dynamic> json) {
    return ShowResult(
      id: json['id'] ?? '',
      dogId: json['dogId'] ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      showName: json['showName'] ?? '',
      judge: json['judge'],
      showClass: json['showClass'] ?? 'Åpen',
      quality: json['quality'] ?? 'Excellent',
      placement: json['placement'],
      certificates: json['certificates'] != null 
          ? List<String>.from(json['certificates'])
          : (json['certificate'] != null ? [json['certificate']] : null), // Bakoverkompatibilitet
      groupResult: json['groupResult'],
      bisResult: json['bisResult'],
      critique: json['critique'],
      notes: json['notes'],
      showType: json['showType'],
      hasCK: json['hasCK'] ?? false,
      classPlacement: json['classPlacement'],
      bestOfSexPlacement: json['bestOfSexPlacement'],
      groupJudge: json['groupJudge'],
      bisJudge: json['bisJudge'],
    );
  }
}

/// Hjelpeklasse for utstillingsstatistikk
class ShowStatistics {
  final int totalShows;
  final int excellentCount;
  final int veryGoodCount;
  final int goodCount;
  final int sufficientCount;
  final int disqualifiedCount;
  final int cannotBeJudgedCount;
  final int ckCount;
  final int birCount;
  final int bimCount;
  // Standard sertifikater
  final int certCount;
  final int resCertCount;
  final int cacibCount;
  final int resCacibCount;
  final int nordiskCertCount;
  final int resNordiskCertCount;
  // Junior sertifikater
  final int juniorCertCount;
  final int juniorNordiskCertCount;
  final int juniorCacibCount;
  // Veteran sertifikater
  final int veteranCertCount;
  final int veteranNordiskCertCount;
  final int veteranCacibCount;
  final int big1Count;
  final int big2Count;
  final int big3Count;
  final int big4Count;
  final int bis1Count;
  final int bis2Count;
  final int bis3Count;
  final int bis4Count;
  // Klasseplasseringer
  final int class1Count;
  final int class2Count;
  final int class3Count;
  final int class4Count;
  // Beste hannhund/tispe plasseringer (BHK/BTK)
  final int bestOfSex1Count;
  final int bestOfSex2Count;
  final int bestOfSex3Count;
  final int bestOfSex4Count;
  final Map<String, JudgeStatistics> judgeStats;

  ShowStatistics({
    required this.totalShows,
    required this.excellentCount,
    required this.veryGoodCount,
    required this.goodCount,
    required this.sufficientCount,
    required this.disqualifiedCount,
    required this.cannotBeJudgedCount,
    required this.ckCount,
    required this.birCount,
    required this.bimCount,
    required this.certCount,
    required this.resCertCount,
    required this.cacibCount,
    required this.resCacibCount,
    required this.nordiskCertCount,
    required this.resNordiskCertCount,
    required this.juniorCertCount,
    required this.juniorNordiskCertCount,
    required this.juniorCacibCount,
    required this.veteranCertCount,
    required this.veteranNordiskCertCount,
    required this.veteranCacibCount,
    required this.big1Count,
    required this.big2Count,
    required this.big3Count,
    required this.big4Count,
    required this.bis1Count,
    required this.bis2Count,
    required this.bis3Count,
    required this.bis4Count,
    required this.class1Count,
    required this.class2Count,
    required this.class3Count,
    required this.class4Count,
    required this.bestOfSex1Count,
    required this.bestOfSex2Count,
    required this.bestOfSex3Count,
    required this.bestOfSex4Count,
    required this.judgeStats,
  });

  /// Beregn statistikk fra en liste med resultater
  factory ShowStatistics.fromResults(List<ShowResult> results) {
    // Beregn dommerstatistikk
    final Map<String, JudgeStatistics> judgeMap = {};
    for (final result in results) {
      if (result.judge != null && result.judge!.isNotEmpty) {
        final judgeName = result.judge!;
        if (!judgeMap.containsKey(judgeName)) {
          judgeMap[judgeName] = JudgeStatistics(name: judgeName);
        }
        judgeMap[judgeName] = judgeMap[judgeName]!.addResult(result);
      }
    }
    
    // Helper function to check if a certificate matches exactly (case-insensitive)
    bool hasCert(ShowResult r, String certName) {
      if (r.certificates == null) return false;
      return r.certificates!.any((c) => c.toLowerCase() == certName.toLowerCase());
    }
    
    return ShowStatistics(
      totalShows: results.length,
      excellentCount: results.where((r) => r.quality == 'Excellent').length,
      veryGoodCount: results.where((r) => r.quality == 'Very Good').length,
      goodCount: results.where((r) => r.quality == 'Good').length,
      sufficientCount: results.where((r) => r.quality == 'Sufficient').length,
      disqualifiedCount: results.where((r) => r.quality == 'Disqualified').length,
      cannotBeJudgedCount: results.where((r) => r.quality == 'Cannot be judged').length,
      ckCount: results.where((r) => r.gotCK).length,
      birCount: results.where((r) => r.placement == 'BIR').length,
      bimCount: results.where((r) => r.placement == 'BIM').length,
      // Standard certificates - exact match only (not containing)
      certCount: results.where((r) => hasCert(r, 'Cert')).length,
      resCertCount: results.where((r) => hasCert(r, 'Res.Cert')).length,
      cacibCount: results.where((r) => hasCert(r, 'Cacib')).length,
      resCacibCount: results.where((r) => hasCert(r, 'Res.Cacib')).length,
      nordiskCertCount: results.where((r) => hasCert(r, 'Nordisk Cert')).length,
      resNordiskCertCount: results.where((r) => hasCert(r, 'Res.Nordisk Cert')).length,
      // Junior certificates
      juniorCertCount: results.where((r) => hasCert(r, 'Junior Cert')).length,
      juniorNordiskCertCount: results.where((r) => hasCert(r, 'Nordisk Junior Cert')).length,
      juniorCacibCount: results.where((r) => hasCert(r, 'Junior Cacib')).length,
      // Veteran certificates
      veteranCertCount: results.where((r) => hasCert(r, 'Veteran Cert')).length,
      veteranNordiskCertCount: results.where((r) => hasCert(r, 'Nordisk Veteran Cert')).length,
      veteranCacibCount: results.where((r) => hasCert(r, 'Veteran Cacib')).length,
      big1Count: results.where((r) => r.groupResult == 'BIG1').length,
      big2Count: results.where((r) => r.groupResult == 'BIG2').length,
      big3Count: results.where((r) => r.groupResult == 'BIG3').length,
      big4Count: results.where((r) => r.groupResult == 'BIG4').length,
      bis1Count: results.where((r) => r.bisResult == 'BIS1').length,
      bis2Count: results.where((r) => r.bisResult == 'BIS2').length,
      bis3Count: results.where((r) => r.bisResult == 'BIS3').length,
      bis4Count: results.where((r) => r.bisResult == 'BIS4').length,
      class1Count: results.where((r) => r.classPlacement == '1').length,
      class2Count: results.where((r) => r.classPlacement == '2').length,
      class3Count: results.where((r) => r.classPlacement == '3').length,
      class4Count: results.where((r) => r.classPlacement == '4').length,
      bestOfSex1Count: results.where((r) => r.bestOfSexPlacement == '1').length,
      bestOfSex2Count: results.where((r) => r.bestOfSexPlacement == '2').length,
      bestOfSex3Count: results.where((r) => r.bestOfSexPlacement == '3').length,
      bestOfSex4Count: results.where((r) => r.bestOfSexPlacement == '4').length,
      judgeStats: judgeMap,
    );
  }

  /// Hent dommere sortert etter antall utstillinger (mest først)
  List<JudgeStatistics> get sortedJudges {
    final judges = judgeStats.values.toList();
    judges.sort((a, b) => b.showCount.compareTo(a.showCount));
    return judges;
  }

  /// Total antall gruppefinaler
  int get totalGroupPlacements => big1Count + big2Count + big3Count + big4Count;

  /// Total antall BIS-plasseringer
  int get totalBISPlacements => bis1Count + bis2Count + bis3Count + bis4Count;
}

/// Statistikk for en enkelt dommer
class JudgeStatistics {
  final String name;
  final int showCount;
  final int excellentCount;
  final int ckCount;
  final int birCount;
  final int bimCount;
  final List<String> resultIds;

  JudgeStatistics({
    required this.name,
    this.showCount = 0,
    this.excellentCount = 0,
    this.ckCount = 0,
    this.birCount = 0,
    this.bimCount = 0,
    this.resultIds = const [],
  });

  JudgeStatistics addResult(ShowResult result) {
    return JudgeStatistics(
      name: name,
      showCount: showCount + 1,
      excellentCount: excellentCount + (result.quality == 'Excellent' ? 1 : 0),
      ckCount: ckCount + (result.gotCK ? 1 : 0),
      birCount: birCount + (result.placement == 'BIR' ? 1 : 0),
      bimCount: bimCount + (result.placement == 'BIM' ? 1 : 0),
      resultIds: [...resultIds, result.id],
    );
  }
}
