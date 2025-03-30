import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Repository/Api/Api.dart';
import '../../Repository/ModelClass/ManulGetModelClass.dart';

part 'get_manual_aqi_event.dart';
part 'get_manual_aqi_state.dart';

class GetManualAqiBloc extends Bloc<GetManualAqiEvent, GetManualAqiState> {
  late ManulGetModelClass  getmanual;
  UserApi userApi = UserApi();

  GetManualAqiBloc() : super(GetManualAqiInitial()) {
    on<FeatchGetManualAqi>((event, emit) async{
      emit (GetManualAqiBlocLoading());
      try{ getmanual=await userApi.getManulGet();
      emit(GetManualAqiBlocLoaded() );
      }
      catch(e){emit (GetManualAqiBlocError());
      print("Errorrrrrrrrrrrrrrrrrrrrrr $e");
      }
    });
  }
}
