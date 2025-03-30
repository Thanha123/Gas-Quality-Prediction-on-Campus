part of 'manual_post_bloc.dart';

@immutable
sealed class ManualPostEvent {}
class FeatchManualPostdata extends  ManualPostEvent {
  final String nh3;
  final String co;
  final String o3;
  final String ch4;


  FeatchManualPostdata({ required this.nh3,required this.co,required this.o3,required this.ch4 });
}