import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:Storyteller/src/models/user_model.dart';
import 'package:Storyteller/src/resources/repository.dart';

final bloc = LoginBloc();

class LoginBloc {
  final repository = Repository();
  final userFetcher = PublishSubject<UserModel>();

  StreamView<UserModel> get getUser => userFetcher.stream;

  fetchUserLogin() async {
    print("1 ~~~~~~~~~~~~~~~~~~");
    try {
      UserModel userModel = await repository.fetchUserLoginState();
      userFetcher.sink.add(userModel);
      print(userModel);
      // fservice init
      print("~~~~~~~~~~~~~~~~~~");
    } catch (e) {
      print("Error == ${e.toString()}");
      if (!userFetcher.isClosed) {
        userFetcher.sink.addError("invalid login");
      }
    }
  }

  loginUserLogin(String username, String password) async {
    if (username != "" && password != "") {
      print("2 ~~~~~~~~~~~~~~~~~~");
      try {
        UserModel userModel =
            await repository.loginUserLogin(username, password);
        userFetcher.sink.add(userModel);
        // fservice init
      } catch (e) {
        print("Error == ${e.toString()}");
        print("2 err ~~~~~~~~~~~~~~~~~~");
        if (!userFetcher.isClosed) {
          userFetcher.sink.addError(e.message);
        }
      }
    }
  }

  dispose() async {
    await userFetcher.drain();
    userFetcher.close();
    // fservice trash
    print("dispose");
  }
}
