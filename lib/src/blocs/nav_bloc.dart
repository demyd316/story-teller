import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:Storyteller/src/models/notification_model.dart';
import 'package:Storyteller/src/resources/repository.dart';
import 'keep_alive_page.dart';

enum NavBarItem { HOME, SEARCH, ADD, ALERT, PROFILE }

class BottomNavBarBloc {
  final repository = Repository();
  final notificationFetcher = PublishSubject<NotificationModel>();
  final StreamController<NavBarItem> _navBarController =
      StreamController<NavBarItem>.broadcast();

  NavBarItem defaultItem = NavBarItem.HOME;

  Stream<NavBarItem> get itemStream => _navBarController.stream;
  StreamView<NotificationModel> get allNotifications =>
      notificationFetcher.stream;

  dispose() async {
    await notificationFetcher.drain();
    notificationFetcher.close();
  }

  fetchAllNotifications() async {
    NotificationModel userModel = await repository.fetchAllNotifications();
    notificationFetcher.sink.add(userModel);
  }

  void pickItem(int i) {
    switch (i) {
      case 0:
        _navBarController.sink.add(NavBarItem.HOME);
        break;
      case 1:
        _navBarController.sink.add(NavBarItem.SEARCH);
        break;
      case 2:
       // _navBarController.sink.add(NavBarItem.ADD);
        break;
      case 3:
        _navBarController.sink.add(NavBarItem.ALERT);
        break;
      case 4:
        _navBarController.sink.add(NavBarItem.PROFILE);
        break;
    }
  }

  close() {
    _navBarController?.close();
  }
}
