import 'package:airquality/Bloc/AllgasesBloc/all_gases_bloc.dart';
import 'package:airquality/Bloc/GetManulAllAqi_Bloc/get_manual_aqi_bloc.dart';
import 'package:airquality/Bloc/ManualPost_Bloc/manual_post_bloc.dart';
import 'package:airquality/Bloc/Overall%20AQI%20Bloc/overall_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'UI/Audentication/Splash.dart';
import 'UI/Home.dart';
import 'UI/Sample.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => OverallBloc(),
              ),
              BlocProvider(
                create: (context) => AllGasesBloc(),
              ),
              BlocProvider(
                create: (context) => ManualPostBloc(),
              ),
              BlocProvider(
                create: (context) => GetManualAqiBloc(),
              ),
            ],
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Flutter Demo',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                home: Home()
            ),
          );
        });
  }
}

