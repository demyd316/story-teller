import 'package:Storyteller/src/ui/search.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../blocs/nav_bloc.dart';
import 'package:Storyteller/src/ui/add_photo.dart';
import 'package:Storyteller/src/ui/newsfeed.dart';
import 'package:Storyteller/src/ui/notifications.dart';
import 'package:Storyteller/src/ui/profile.dart';
import 'package:line_icons/line_icons.dart';
import 'globals.dart' as global;
import '../blocs/profile_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import 'keep_alive_page.dart';

class StoryTellerBottom extends StatefulWidget {
  @override
  MyBottomNavigationBar createState() => MyBottomNavigationBar();
}

class MyBottomNavigationBar extends State<StoryTellerBottom>
    with AutomaticKeepAliveClientMixin {
  bool keepAlive = false;
  BottomNavBarBloc _bottomNavBarBloc;
  StreamSubscription connectivitySubscription;
  var _currentIndex = 0;
  Timer timer, freq;
  int counter = 1;
  bool user = true;
  bool new_notification = false;

  Future doAsyncStuff() async {
    keepAlive = true;
    updateKeepAlive();
    // Keeping alive...

    await Future.delayed(Duration(seconds: 10));

    keepAlive = true;
    updateKeepAlive();
    // Can be disposed whenever now.
  }

  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    bloc.fetchUser(0);
    doAsyncStuff();
    bloc.userDetail.listen(
      (data) {
        if (data != null) {
          if (user == true) {
            print(data.user.id);
            global.userId = data.user.id;
            global.blockList = data.user.block;
            user = false;
          }
        }
      },
    );

    const _duration = const Duration(milliseconds: 2500);
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {});

    freq = Timer.periodic(
      _duration,
      (timer) {
        connectivitySubscription.resume();

        check().then(
          (internet) {
            if (internet == false) {
            } else {
              _bottomNavBarBloc.fetchAllNotifications();
              _bottomNavBarBloc.allNotifications.listen((onData) {
                if (onData.datas.length > 0) {
                  setState(() {
                    new_notification = true;
                  });
                } else {
                  setState(() {
                    new_notification = false;
                  });
                }
                _bottomNavBarBloc.dispose();
              });
            }
          },
        );
      },
    );

    _bottomNavBarBloc = BottomNavBarBloc();
  }

  @override
  void dispose() {
    timer?.cancel();
    _bottomNavBarBloc.close();
    bloc.dispose();
    super.dispose();
  }

  refresh() {}

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double bottomBarHeight = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: StreamBuilder<NavBarItem>(
        stream: _bottomNavBarBloc.itemStream,
        initialData: _bottomNavBarBloc.defaultItem,
        builder: (BuildContext context, AsyncSnapshot<NavBarItem> snapshot) {
          switch (snapshot.data) {
            case NavBarItem.HOME:
              return PhotoFeed();
            case NavBarItem.SEARCH:
              return SearchPageTab();
            case NavBarItem.ADD:
              return PhotoForm();
            case NavBarItem.ALERT:
              return StoryTellerNotification();
            case NavBarItem.PROFILE:
              return StorytellerProfile(0, false, refresh);
          }

          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder(
        stream: _bottomNavBarBloc.itemStream,
        initialData: _bottomNavBarBloc.defaultItem,
        builder: (BuildContext context, AsyncSnapshot<NavBarItem> snapshot) {
          return Container(
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Color.fromRGBO(207, 207, 207, 0.50),
                          width: 0.6))),
              child: BottomNavigationBar(
                elevation: 0,
                fixedColor: Color.fromRGBO(0, 0, 0, 1),
                unselectedItemColor: Color.fromRGBO(152, 152, 152, 1),
                type: BottomNavigationBarType.fixed,
                currentIndex: snapshot.data.index,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: _bottomNavBarBloc.pickItem,
                items: [
                  BottomNavigationBarItem(
                    title: new Text("Discover",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        )),
                    // activeIcon: new Image.asset('assets/navigation/home1.png', width: 25, height: 25, ),
                    activeIcon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, 0, 0.0),
                          child: new Image.asset(
                            'assets/navigation/h2.png',
                            width: 22,
                            height: 22,
                          ),
                          //Icon(LineIcons.home, size: 27.5),
                        ),
                      ],
                    ),

                    icon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, 0, 0.0),
                          child: new Image.asset(
                            'assets/navigation/h01.png',
                            width: 22,
                            height: 22,
                          ),
                          //Icon(LineIcons.home, size: 27.5),
                        ),
                      ],
                    ),
                  ),
                  BottomNavigationBarItem(
                    title: new Text("Search",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        )),
                    activeIcon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, 0, 0.0),
                          child: new Image.asset(
                            'assets/navigation/search2.png',
                            width: 22,
                            height: 22,
                          ),
                          //Icon(  LineIcons.search,size: 27.5,),
                        ),
                      ],
                    ),
                    icon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, 0, 0.0),
                          child:
                              //SvgPicture.network( 'https://www.flaticon.com/svg/static/icons/svg/3430/3430331.svg', width: 27, height: 27, color: Color.fromRGBO(152, 152, 152, 1),),
                              // Icon(LineIcons.search, size: 27.5),
                              new Image.asset(
                            'assets/navigation/search1.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BottomNavigationBarItem(
                    title: new Text("Post",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        )),
                    icon: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showMaterialModalBottomSheet(
                                backgroundColor: Colors.white,
                                elevation: 0.90,
                                isDismissible: true,
                                barrierColor: Colors.black.withOpacity(0.20),
                                enableDrag: true,
                                expand: false,
                                context: context,
                                builder: (context) => ConstrainedBox(
                                      constraints: new BoxConstraints(
                                          //  minHeight: screenSize.height - 120,
                                          //  maxHeight: screenSize.height - 120,
                                          ),
                                      child: PhotoForm(),
                                    ));
                          },
                          child: Container(
                            transform: Matrix4.translationValues(0.0, 1.0, 0.0),
                            child: Stack(
                              children: <Widget>[
                                new Icon(LineIcons.plus_square,
                                    size: 29, color: Colors.transparent),
                                Positioned(
                                  // draw a red marble
                                  top: 0.0,
                                  right: 0.0,
                                  child: Container(
                                    transform: Matrix4.translationValues(
                                        -1.8, 2.0, 0.0),
                                    child: new Image.asset(
                                      'assets/navigation/add.png',
                                      width: 23.5,
                                      height: 23.5,
                                    ),
                                    // Icon( MaterialIcons.add_box,size: 27.5, color: Colors.black,),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  BottomNavigationBarItem(
                    title: new Text("Activity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        )),
                    activeIcon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, -1.0, 0.0),
                          child: Stack(
                            children: <Widget>[
                              Icon(LineIcons.heart, size: 28.3),
                              new_notification == true
                                  ? Positioned(
                                      // draw a red marble
                                      top: 0.0,
                                      right: 0.0,
                                      child: Container(
                                        transform: Matrix4.translationValues(
                                            4.0, 1.0, 0.0),
                                        child: Container(
                                          decoration: new BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      100)),
                                          height: 13.2,
                                          width: 13.2,
                                          child: Icon(Icons.brightness_1,
                                              size: 11.2, color: Colors.red),
                                        ),
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    icon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, -1.0, 0.0),
                          child: Stack(
                            children: <Widget>[
                              new Icon(LineIcons.heart_o,
                                  size: 28.3, color: Colors.black),
                              new_notification == true
                                  ? new Positioned(
                                      // draw a red marble
                                      top: 0.0,
                                      right: 0.0,
                                      child: Container(
                                        transform: Matrix4.translationValues(
                                            4.0, 1.0, 0.0),
                                        child: Container(
                                          decoration: new BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      100)),
                                          height: 13.2,
                                          width: 13.2,
                                          child: Icon(Icons.brightness_1,
                                              size: 11.2, color: Colors.red),
                                        ),
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  BottomNavigationBarItem(
                    title: new Text("Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        )),
                    activeIcon: Column(
                      children: [
                        Container(
                          transform: Matrix4.translationValues(0.0, 0, 0.0),
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.black, // set border color
                                width: 1.3), // set border width
                            borderRadius: BorderRadius.all(Radius.circular(
                                50.0)), // set rounded corner radius
                          ),
                          child: Container(
                            padding: const EdgeInsets.only(
                              left: 1.7,
                              top: 1.7,
                              bottom: 1.7,
                              right: 1.7,
                            ),
                            color: Colors.transparent,
                            width: 25,
                            height: 25,
                            transform: Matrix4.translationValues(0.0, 0.0, 0.0),
                            child: global.avatar == null
                                ? Container()
                                : CircleAvatar(
                                    radius: 21,
                                    backgroundImage:
                                        new CachedNetworkImageProvider(
                                      (global.avatar),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    icon: Column(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          transform: Matrix4.translationValues(0.0, -0.5, 0.0),
                          child: global.avatar == null
                              ? SizedBox(
                                  height: 21.0,
                                  child: ClipRRect(
                                    borderRadius:
                                        new BorderRadius.circular(100.0),
                                    child: Shimmer(
                                      duration:
                                          Duration(seconds: 1), //Default value
                                      interval: Duration(
                                          seconds:
                                              1), //Default value: Duration(seconds: 0)
                                      color: Colors.black, //Default value
                                      enabled: true, //Default value
                                      direction: ShimmerDirection
                                          .fromLTRB(), //Default Value
                                      child: Container(
                                        width: 110,
                                        height: 190,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              new BorderRadius.circular(100),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 21,
                                  backgroundImage:
                                      new CachedNetworkImageProvider(
                                    (global.avatar),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ));
        },
      ),
    );
  }
}
