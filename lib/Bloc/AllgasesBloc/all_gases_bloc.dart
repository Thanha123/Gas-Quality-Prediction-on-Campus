import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Repository/Api/Api.dart';
import '../../Repository/ModelClass/LatestPredictionModel.dart';

part 'all_gases_event.dart';
part 'all_gases_state.dart';

class AllGasesBloc extends Bloc<AllGasesEvent, AllGasesState> {
  late LatestPredictionModel  latestPrediction;
  UserApi userApi = UserApi();
  AllGasesBloc() : super(AllGasesInitial()) {
    on<FeatchAllGases>((event, emit) async{



      emit (AllGasesLoading());
      try{ latestPrediction=await userApi.getLatestPrediction();
      emit(AllGasesBlocLoaded() );

      }
      catch(e){emit (AllGasesBlocError());
      print("Errorrrrrrrrrrrrrrrrrrrrrr $e");
      }


    });
  }
}
