import 'dart:convert';
import 'dart:core';


import 'package:http/http.dart';

import '../ModelClass/LatestPredictionModel.dart';
import '../ModelClass/ManualPostModelClass.dart';
import '../ModelClass/ManulGetModelClass.dart';
import '../ModelClass/OverallAQiModel.dart';
import 'ApiClient.dart';



class UserApi {
  ApiClient apiClient = ApiClient();
//Siginup

  Future<OverallAqiModel> getToatalAqi() async {
    String trendingpath =
        'http://192.168.1.36:5000/timeseries';

    var body = {};
    print("printing body$body");
    Response response =
    await apiClient.invokeAPI(trendingpath, 'GET', jsonEncode(body));

    return OverallAqiModel.fromJson(jsonDecode(response.body));
  }


  // Latest Prediction

  Future<LatestPredictionModel> getLatestPrediction() async {
    String trendingpath =
        'http://192.168.1.36:5000/predict';

    var body = {};
    print("printing body$body");
    Response response =
    await apiClient.invokeAPI(trendingpath, 'GET', jsonEncode(body));

    return LatestPredictionModel.fromJson(jsonDecode(response.body));
  }


// MANUAL POST FOR ADD DATA
  Future<ManualPostModelClass> getManualPost(String nh3, String co,String o3,String ch4) async {
    String trendingpath =
        'http://192.168.1.36:5000/predict/manual';

    var body = {
      "NH3_ppm": double.tryParse(nh3) ?? 0.0,
      "CO_ppm": double.tryParse(co) ?? 0.0,
      "O3_ppm": double.tryParse(o3) ?? 0.0,
      "CH4_ppm": double.tryParse(ch4) ?? 0.0,
    };
    print("printing body$body");
    Response response =
    await apiClient.invokeAPI(trendingpath, 'POST', jsonEncode(body));

    return ManualPostModelClass.fromJson(jsonDecode(response.body));
  }

// Getting  Manual Added Get Method

  Future<ManulGetModelClass> getManulGet() async {
    String trendingpath =
        'http://192.168.1.36:5000/predict/manual';

    var body = {};
    print("printing body$body");
    Response response =
    await apiClient.invokeAPI(trendingpath, 'GET', jsonEncode(body));

    return ManulGetModelClass.fromJson(jsonDecode(response.body));
  }



}