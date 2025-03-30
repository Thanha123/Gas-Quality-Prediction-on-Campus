class OverallAqiModel {
  List<Data20250318>? data20250318;
  List<Data20250320>? data20250320;

  OverallAqiModel({this.data20250318, this.data20250320});

  OverallAqiModel.fromJson(Map<String, dynamic> json) {
    if (json["2025-03-18"] is List) {
      data20250318 = (json["2025-03-18"] as List)
          .map((e) => Data20250318.fromJson(e))
          .toList();
    }
    if (json["2025-03-20"] is List) {
      data20250320 = (json["2025-03-20"] as List)
          .map((e) => Data20250320.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (data20250318 != null) {
      data["2025-03-18"] =
          data20250318?.map((e) => e.toJson()).toList();
    }
    if (data20250320 != null) {
      data["2025-03-20"] =
          data20250320?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Data20250318 {
  double? overallAqi;
  String? time;

  Data20250318({this.overallAqi, this.time});

  Data20250318.fromJson(Map<String, dynamic> json) {
    overallAqi = (json["Overall_AQI"] as num?)?.toDouble();
    time = json["time"] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["Overall_AQI"] = overallAqi;
    data["time"] = time;
    return data;
  }
}

class Data20250320 {
  double? overallAqi;
  String? time;

  Data20250320({this.overallAqi, this.time});

  Data20250320.fromJson(Map<String, dynamic> json) {
    overallAqi = (json["Overall_AQI"] as num?)?.toDouble();
    time = json["time"] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["Overall_AQI"] = overallAqi;
    data["time"] = time;
    return data;
  }
}
