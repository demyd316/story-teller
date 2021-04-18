import 'dart:convert';
import 'package:Storyteller/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Storyteller/src/ui/profile.dart';
import '../blocs/notification_bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'conversation_send.dart';
import 'dart:async';
import 'globals.dart' as global;
import 'package:Storyteller/src/ui/video_notifications.dart';
import 'package:mime/mime.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:ionicons/ionicons.dart' as ion;

class StoryTellerNotification extends StatefulWidget {
  @override
  PagewiseGridViewExample createState() => PagewiseGridViewExample();
}

class PagewiseGridViewExample extends State<StoryTellerNotification> {
  Future<bool> check() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  bool user = true;
  @override
  void initState() {
    super.initState();
    bloc.fetchUser(0);
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

    check().then(
      (internet) {
        if (internet == false) {
        } else {
          bloc.fetchAllNotifications();
          bloc.userFetcherStatus.listen((onData) {
            bloc.fetchAllNotifications();
          });
          bloc.notificationFetcherStatus.listen((onData) {
            bloc.fetchAllNotifications();
          });
        }
      },
    );
  }

  bool isBlock(int id) {
    var blocklist = global.blockList.split(",");
    return blocklist.contains(id.toString());
  }

  bool isBlocked(String list) {
    var id = global.userId;
    var blocklist = list.split(",");
    return blocklist.contains(id.toString());
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  checkFileType(String url) {
    String mimeStr = lookupMimeType(url);
    var fileType = mimeStr.split('/');
    print(fileType[0]);
    return fileType[0];
  }

  refresh() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildList(),
          Container(
            height: MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildList() {
    final screenSize = MediaQuery.of(context).size;
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          elevation: 0.6,
          expandedHeight: kToolbarHeight,
          pinned: true,
          floating: true,
          actions: [
            GestureDetector(
              onTap: () => {bloc.readNotifications()},
              child: Container(
                margin: EdgeInsets.only(right: 20),
                child: Center(
                  child: Text(
                    AppLocalizations.instance.text('clear'),
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'SFProDisplayRegular',
                    ),
                  ),
                ),
              ),
            ),

            // IconButton(
            //   icon: Icon(Feather.trash, size: 26.0),
            //   padding: EdgeInsets.only(right: 20.0),
            ///onPressed: () {
            //      bloc.readNotifications();
            //    },
            //   )
          ],
          centerTitle: false,
          title: Text(
            AppLocalizations.instance.text('activity'),
            style: TextStyle(
              fontFamily: 'SFProDisplayBold',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        StreamBuilder(
          stream: bloc.allNotifications,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data.datas.length == 0) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: screenSize.height - 200,
                    child: Center(
                      child: Text(AppLocalizations.instance.text('noactivity'),
                          style: TextStyle(
                            color: Color.fromRGBO(148, 148, 148, 1),
                            fontSize: 12.7,
                          )),
                    ),
                  ),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      dynamic notificationdata =
                          json.decode(snapshot.data.datas[index].data);
                      // print(snapshot.data.datas[index].data);
                      switch (snapshot.data.datas[index].type) {
                        case "App\\Notifications\\StartedToFollowNotification":
                          return isBlock(notificationdata["user"]["id"]) ==
                                  false
                              ? Dismissible(
                                  key: Key(snapshot.data.datas[index].id),
                                  background: Container(
                                    alignment: AlignmentDirectional.centerStart,
                                    color: Colors.red,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 0.0, 0.0, 0.0),
                                      child: Icon(
                                        ion.Ionicons.trash_bin_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  direction: DismissDirection.startToEnd,
                                  onDismissed: (direction) {
                                    print(snapshot.data.datas[index].id);
                                    bloc.readNotification(
                                        snapshot.data.datas[index].id);
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        padding:
                                            EdgeInsets.only(bottom: 5, top: 5),
                                        margin: EdgeInsets.only(
                                            bottom: 13, left: 13, right: 13),
                                        elevation: 0,
                                        backgroundColor:
                                            Color.fromRGBO(78, 187, 31, 1),
                                        content: Text(
                                          AppLocalizations.instance
                                              .text('delete'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Vibrate.feedback(FeedbackType.medium);
                                  },
                                  child: InkWell(
                                    child: GestureDetector(
                                        onTap: () => {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      StorytellerProfile(
                                                          notificationdata[
                                                              "user"]["id"],
                                                          false,
                                                          refresh),
                                                ),
                                              ),
                                            },
                                        child: Column(children: <Widget>[
                                          ListTile(
                                            leading: ClipRRect(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      30.0),
                                              child: CachedNetworkImage(
                                                height: kToolbarHeight / 1,
                                                width: kToolbarHeight / 1,
                                                fit: BoxFit.cover,
                                                imageUrl:
                                                    (notificationdata["user"]
                                                        ["avatar"]),
                                              ),
                                            ),
                                            title: new Text(
                                              notificationdata["user"]["name"],
                                              style: TextStyle(
                                                fontFamily: 'SFProDisplayBold',
                                              ),
                                            ),
                                            subtitle: new Text(
                                              AppLocalizations.instance
                                                  .text('startfollow'),
                                            ),
                                            trailing: ButtonTheme(
                                              height: kToolbarHeight / 1.7,
                                              minWidth: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  3.7,
                                              child: FlatButton(
                                                color: Color.fromRGBO(
                                                    0, 141, 252, 1),
                                                shape:
                                                    new RoundedRectangleBorder(
                                                        borderRadius:
                                                            new BorderRadius
                                                                .circular(5.0)),
                                                child: new Text(
                                                  AppLocalizations.instance
                                                      .text('profile'),
                                                  style: new TextStyle(
                                                      fontSize: 14.0,
                                                      color: Colors.white,
                                                      fontFamily:
                                                          'SFProDisplayRegular'),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          StorytellerProfile(
                                                              notificationdata[
                                                                  "user"]["id"],
                                                              false,
                                                              refresh),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Divider(
                                            color: Color.fromRGBO(
                                                207, 207, 207, 0.60),
                                            height: 1,
                                            thickness: 0,
                                            indent: 0,
                                            endIndent: 0,
                                          ),
                                        ])),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StorytellerProfile(
                                                  notificationdata["user"]
                                                      ["id"],
                                                  false,
                                                  refresh),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container();

                          break;
                        case "App\\Notifications\\LikedPhotoNotification":
                          return isBlock(notificationdata["user"]["id"]) ==
                                  false
                              ? Dismissible(
                                  key: Key(snapshot.data.datas[index].id),
                                  background: Container(
                                    alignment: AlignmentDirectional.centerStart,
                                    color: Colors.red,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 0.0, 0.0, 0.0),
                                      child: Icon(
                                        ion.Ionicons.trash_bin_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  direction: DismissDirection.startToEnd,
                                  onDismissed: (direction) {
                                    print(snapshot.data.datas[index].id);
                                    bloc.readNotification(
                                        snapshot.data.datas[index].id);
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        padding:
                                            EdgeInsets.only(bottom: 5, top: 5),
                                        margin: EdgeInsets.only(
                                            bottom: 13, left: 13, right: 13),
                                        elevation: 0,
                                        backgroundColor:
                                            Color.fromRGBO(78, 187, 31, 1),
                                        content: Text(
                                          AppLocalizations.instance
                                              .text('delete'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Vibrate.feedback(FeedbackType.medium);
                                  },
                                  child: Column(children: <Widget>[
                                    ListTile(
                                      leading: ClipRRect(
                                        borderRadius:
                                            new BorderRadius.circular(30.0),
                                        child: CachedNetworkImage(
                                          height: kToolbarHeight / 1,
                                          width: kToolbarHeight / 1,
                                          fit: BoxFit.cover,
                                          imageUrl: (notificationdata["user"]
                                              ["avatar"]),
                                        ),
                                      ),
                                      title: new Text(
                                        notificationdata["user"]["name"],
                                        style: TextStyle(
                                          fontFamily: 'SFProDisplayBold',
                                        ),
                                      ),
                                      subtitle: new Text(
                                        AppLocalizations.instance
                                            .text('likedpost'),
                                      ),
                                      trailing: ClipRRect(
                                        borderRadius:
                                            new BorderRadius.circular(10.0),
                                        child: checkFileType(
                                                  notificationdata["post"]
                                                      ["image"],
                                                ) ==
                                                "image"
                                            ? CachedNetworkImage(
                                                width: kToolbarHeight / 1.0,
                                                height: kToolbarHeight / 1.0,
                                                placeholder: (c, d) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.0,
                                                    ),
                                                  );
                                                },
                                                fit: BoxFit.cover,
                                                imageUrl:
                                                    notificationdata["post"]
                                                        ["image"],
                                              )
                                            : Container(
                                                width: kToolbarHeight / 1.0,
                                                height: kToolbarHeight / 1.0,
                                                child: VideoClip(
                                                  url: notificationdata["post"]
                                                      ["image"],
                                                ),
                                              ),
                                      ),
                                    ),
                                    Divider(
                                      color:
                                          Color.fromRGBO(207, 207, 207, 0.60),
                                      height: 1,
                                      thickness: 0,
                                      indent: 0,
                                      endIndent: 0,
                                    ),
                                  ]),
                                )
                              : Container();

                          break;
                        case "App\\Notifications\\NewComment":
                          return isBlock(notificationdata["user"]["id"]) ==
                                  false
                              ? Dismissible(
                                  key: Key(snapshot.data.datas[index].id),
                                  background: Container(
                                    alignment: AlignmentDirectional.centerStart,
                                    color: Colors.red,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 0.0, 0.0, 0.0),
                                      child: Icon(
                                         ion.Ionicons.trash_bin_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  direction: DismissDirection.startToEnd,
                                  onDismissed: (direction) {
                                    print(snapshot.data.datas[index].id);
                                    bloc.readNotification(
                                        snapshot.data.datas[index].id);
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        padding:
                                            EdgeInsets.only(bottom: 5, top: 5),
                                        margin: EdgeInsets.only(
                                            bottom: 13, left: 13, right: 13),
                                        elevation: 0,
                                        backgroundColor:
                                            Color.fromRGBO(78, 187, 31, 1),
                                        content: Text(
                                          AppLocalizations.instance
                                              .text('delete'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Vibrate.feedback(FeedbackType.medium);
                                  },
                                  child: Column(children: <Widget>[
                                    ListTile(
                                      leading: ClipRRect(
                                        borderRadius:
                                            new BorderRadius.circular(30.0),
                                        child: CachedNetworkImage(
                                          height: kToolbarHeight / 1,
                                          width: kToolbarHeight / 1,
                                          fit: BoxFit.cover,
                                          imageUrl: (notificationdata["user"]
                                              ["avatar"]),
                                        ),
                                      ),
                                      title: new Text(
                                        notificationdata["user"]["name"],
                                        style: TextStyle(
                                          fontFamily: 'SFProDisplayBold',
                                        ),
                                      ),
                                      subtitle: new Text(
                                        'New comment',
                                      ),
                                      trailing: ClipRRect(
                                        borderRadius:
                                            new BorderRadius.circular(10.0),
                                        child: CachedNetworkImage(
                                          height: kToolbarHeight / 1.2,
                                          width: kToolbarHeight / 1.2,
                                          fit: BoxFit.cover,
                                          imageUrl: notificationdata["post"]
                                              ["image"],
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      color:
                                          Color.fromRGBO(207, 207, 207, 0.60),
                                      height: 1,
                                      thickness: 0,
                                      indent: 0,
                                      endIndent: 0,
                                    ),
                                  ]),
                                )
                              : Container();

                          break;
                        case "App\\Notifications\\NewConversation":
                          return isBlock(notificationdata["from"]["id"]) ==
                                  false
                              ? Dismissible(
                                  key: Key(snapshot.data.datas[index].id),
                                  background: Container(
                                    alignment: AlignmentDirectional.centerStart,
                                    color: Colors.red,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 0.0, 0.0, 0.0),
                                      child: Icon(
                                        ion.Ionicons.trash_bin_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  direction: DismissDirection.startToEnd,
                                  onDismissed: (direction) {
                                    print(snapshot.data.datas[index].id);
                                    bloc.readNotification(
                                        snapshot.data.datas[index].id);
                                  },
                                  child: InkWell(
                                    child: Column(children: <Widget>[
                                      ListTile(
                                        leading: ClipRRect(
                                          borderRadius:
                                              new BorderRadius.circular(30.0),
                                          child: CachedNetworkImage(
                                            height: kToolbarHeight / 1,
                                            width: kToolbarHeight / 1,
                                            fit: BoxFit.cover,
                                            imageUrl: (notificationdata["from"]
                                                ["avatar"]),
                                          ),
                                        ),
                                        title: new Text(
                                          notificationdata["from"]["name"],
                                          style: TextStyle(
                                            fontFamily: 'SFProDisplayBold',
                                          ),
                                        ),
                                        subtitle: new Text(
                                          AppLocalizations.instance
                                              .text('recivedmessage'),
                                        ),
                                        trailing: ButtonTheme(
                                          height: kToolbarHeight / 1.7,
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3.7,
                                          child: FlatButton(
                                            color:
                                                Color.fromRGBO(0, 141, 252, 1),
                                            shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        5.0)),
                                            child: new Text(
                                              AppLocalizations.instance
                                                  .text('respond'),
                                              style: new TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.white,
                                                  fontFamily:
                                                      'SFProDisplayRegular'),
                                            ),
                                            onPressed: () {
                                              print(notificationdata);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ConversationSendForm(
                                                          notificationdata[
                                                              "from"]["id"]),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        color:
                                            Color.fromRGBO(207, 207, 207, 0.60),
                                        height: 1,
                                        thickness: 0,
                                        indent: 0,
                                        endIndent: 0,
                                      ),
                                    ]),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StorytellerProfile(
                                                  notificationdata["from"]
                                                      ["id"],
                                                  false,
                                                  refresh),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container();

                          break;
                      }

                      return Container();
                    },
                    childCount: snapshot.data.datas.length,
                  ),
                );
              }
            } else if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Container(
                  height: 50.0,
                  child: Center(
                    child: Text(snapshot.error.toString()),
                  ),
                ),
              );
            }

            return SliverToBoxAdapter(
              child: Container(
                height: 50.0,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
