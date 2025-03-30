import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../Repository/Api/Api.dart';
import '../../Repository/ModelClass/ManualPostModelClass.dart';

part 'manual_post_event.dart';
part 'manual_post_state.dart';

class ManualPostBloc extends Bloc<ManualPostEvent, ManualPostState> {
  late ManualPostModelClass  manualPost;
  UserApi userApi = UserApi();

  ManualPostBloc() : super(ManualPostInitial()) {
    on<FeatchManualPostdata>((event, emit)async {

      emit (ManualPostBlocLoading());
      try{ manualPost=await userApi.getManualPost(event.nh3, event.co, event.o3, event.ch4);
      emit(ManualPostBlocLoaded() );

      }
      catch(e){emit (ManualPostBlocError());
      print("Errorrrrrrrrrrrrrrrrrrrrrr $e");
      }


    });
  }
}
