class ManualPostModelClass {
  ManualPostModelClass({
      this.ch4aqi, 
      this.cH4Category, 
      this.cH4Ppm, 
      this.coaqi, 
      this.cOCategory, 
      this.cOPpm, 
      this.nh3aqi, 
      this.nH3Category, 
      this.nH3Ppm, 
      this.o3aqi, 
      this.o3Category, 
      this.o3Ppm, 
      this.overallAQI, 
      this.overallCategory, 
      this.timestamp,});

  ManualPostModelClass.fromJson(dynamic json) {
    ch4aqi = json['CH4_AQI'];
    cH4Category = json['CH4_Category'];
    cH4Ppm = json['CH4_ppm'];
    coaqi = json['CO_AQI'];
    cOCategory = json['CO_Category'];
    cOPpm = json['CO_ppm'];
    nh3aqi = json['NH3_AQI'];
    nH3Category = json['NH3_Category'];
    nH3Ppm = json['NH3_ppm'];
    o3aqi = json['O3_AQI'];
    o3Category = json['O3_Category'];
    o3Ppm = json['O3_ppm'];
    overallAQI = json['Overall_AQI'];
    overallCategory = json['Overall_Category'];
    timestamp = json['timestamp'];
  }
  double? ch4aqi;
  String? cH4Category;
  double? cH4Ppm;
  double? coaqi;
  String? cOCategory;
  double? cOPpm;
  double? nh3aqi;
  String? nH3Category;
  double? nH3Ppm;
  double? o3aqi;
  String? o3Category;
  double? o3Ppm;
  double? overallAQI;
  String? overallCategory;
  String? timestamp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CH4_AQI'] = ch4aqi;
    map['CH4_Category'] = cH4Category;
    map['CH4_ppm'] = cH4Ppm;
    map['CO_AQI'] = coaqi;
    map['CO_Category'] = cOCategory;
    map['CO_ppm'] = cOPpm;
    map['NH3_AQI'] = nh3aqi;
    map['NH3_Category'] = nH3Category;
    map['NH3_ppm'] = nH3Ppm;
    map['O3_AQI'] = o3aqi;
    map['O3_Category'] = o3Category;
    map['O3_ppm'] = o3Ppm;
    map['Overall_AQI'] = overallAQI;
    map['Overall_Category'] = overallCategory;
    map['timestamp'] = timestamp;
    return map;
  }

}