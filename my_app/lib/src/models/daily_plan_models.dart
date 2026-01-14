class DailyPlanResult {
  final String summary;
  final List<DailyPlanItem> plan;
  final List<String> tips;

  DailyPlanResult({
    required this.summary,
    required this.plan,
    required this.tips,
  });

  factory DailyPlanResult.fromJson(Map<String, dynamic> json) {
    return DailyPlanResult(
      summary: json['summary']?.toString() ?? 'Your plan for today',
      plan: (json['plan'] as List<dynamic>? ?? [])
          .map((e) => DailyPlanItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      tips: (json['tips'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class DailyPlanItem {
  final String time;     
  final String title;   
  final String details; 

  DailyPlanItem({
    required this.time,
    required this.title,
    required this.details,
  });

  factory DailyPlanItem.fromJson(Map<String, dynamic> json) {
    return DailyPlanItem(
      time: json['time']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
    );
  }
}
