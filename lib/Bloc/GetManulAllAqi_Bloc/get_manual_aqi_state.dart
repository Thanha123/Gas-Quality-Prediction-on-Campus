part of 'get_manual_aqi_bloc.dart';

@immutable
sealed class GetManualAqiState {}

final class GetManualAqiInitial extends GetManualAqiState {}
class GetManualAqiBlocLoading extends  GetManualAqiState {}
class GetManualAqiBlocLoaded extends  GetManualAqiState {}
class GetManualAqiBlocError extends  GetManualAqiState {}