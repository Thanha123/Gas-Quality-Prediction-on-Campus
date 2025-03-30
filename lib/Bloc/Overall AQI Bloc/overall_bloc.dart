import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Repository/Api/Api.dart';
import '../../Repository/ModelClass/OverallAQiModel.dart';

part 'overall_event.dart';
part 'overall_state.dart';

class OverallBloc extends Bloc<OverallEvent, OverallState> {
  late OverallAqiModel  overall;
  UserApi userApi = UserApi();

  OverallBloc() : super(OverallInitial()) {

    on<FeatchOverall>((event, emit)async {

      emit (OverallLoading());
      try{ overall=await userApi.getToatalAqi();
      emit(OverallBlocLoaded() );

      }
      catch(e){emit (OverallBlocError());
      print("Errorrrrrrrrrrrrrrrrrrrrrr $e");
      }


    });
  }
}
