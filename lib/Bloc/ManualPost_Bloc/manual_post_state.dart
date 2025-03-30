part of 'manual_post_bloc.dart';

@immutable
sealed class ManualPostState {}

final class ManualPostInitial extends ManualPostState {}
class ManualPostBlocLoading extends  ManualPostState {}
class ManualPostBlocLoaded extends  ManualPostState {}
class ManualPostBlocError extends  ManualPostState {}