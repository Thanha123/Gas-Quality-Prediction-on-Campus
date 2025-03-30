part of 'all_gases_bloc.dart';

@immutable
sealed class AllGasesState {}

final class AllGasesInitial extends AllGasesState {}
class AllGasesLoading extends  AllGasesState {}
class AllGasesBlocLoaded extends  AllGasesState {}
class AllGasesBlocError extends  AllGasesState {}