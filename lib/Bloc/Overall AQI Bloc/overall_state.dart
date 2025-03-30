part of 'overall_bloc.dart';

@immutable
sealed class OverallState {}

final class OverallInitial extends OverallState {}
class OverallLoading extends  OverallState {}
class OverallBlocLoaded extends  OverallState {}
class OverallBlocError extends  OverallState {}