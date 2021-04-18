import 'dart:async';
import 'package:Storyteller/src/ui/profile.dart';
import 'package:Storyteller/app_localizations.dart';
import 'package:Storyteller/src/models/comment_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import '../blocs/comment_bloc.dart';
import 'globals.dart' as global;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_icons/flutter_icons.dart' as ico;

class Comments extends StatefulWidget {
  final int toPostIdController;
  Comments(this.toPostIdController, {Key key10}) : super(key: key10);

  @override
  _Comments createState() => new _Comments();
}

class _Comments extends State<Comments> {
  TextEditingController commentController = TextEditingController();

  StreamSubscription connectivitySubscription;
  Timer timer;

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
            global.avatar = data.user.avatar;
            user = false;
          }
        }
      },
    );
    const oneSec = const Duration(seconds: 2);
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {});

    timer = Timer.periodic(
      oneSec,
      (timer) {
        connectivitySubscription.resume();
        check().then(
          (internet) {
            if (internet == false) {
            } else {
              print(widget.toPostIdController);
              bloc.fetchComment(widget.toPostIdController);
              bloc.dispose();
            }
          },
        );
      },
    );
  }

  refresh() {}

  bool widgetVisible = true;

  void showWidget() {
    setState(() {
      widgetVisible = true;
    });
  }

  void hideWidget() {
    setState(() {
      widgetVisible = false;
    });
  }

  @override
  void dispose() {
    timer.cancel();
    bloc.dispose();
    super.dispose();
  }

  var emojiheight = 0.0;

  void smile() {
    String newText = '😍';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile2() {
    String newText = '😊';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile3() {
    String newText = '🤤';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile4() {
    String newText = '😂';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile5() {
    String newText = '😎';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile6() {
    String newText = '🤩';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile7() {
    String newText = '👍';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile8() {
    String newText = '👏';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  void smile9() {
    String newText = '🤟';
    var newValue = commentController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length, //offset to Last Character
      ),
      composing: TextRange.empty,
    );
    commentController.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(43.0),
            child: AppBar(
              // backgroundColor: Color.fromRGBO(245, 245, 245, 1),
              automaticallyImplyLeading: false,
              elevation: 0.6,
              title: Text(
                AppLocalizations.instance.text('comments'),
                style: TextStyle(
                  fontFamily: "SFProDisplayBold",
                  fontSize: 17.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // backgroundColor: Color.fromRGBO(247, 247, 247, 0.80),
          body: GestureDetector(
            onTap: () {
              // call this method here to hide soft keyboard
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: StreamBuilder(
              stream: bloc.commentFetcher,
              builder: (context, AsyncSnapshot<CommentModel> snapshot) {
                if (snapshot.hasData) {
                  return buildList(snapshot);
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          ),
        ),
      ],
    );
  }

  Widget buildList(AsyncSnapshot<CommentModel> snapshot) {
    final screenSize = MediaQuery.of(context).size;
    double bottomBarHeight = MediaQuery.of(context).padding.bottom;
    print(snapshot.data.data.length);
    return Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            top: 0,
            bottom: bottomBarHeight + 90,
            left: 10,
            right: 10,
          ),
          child: ListView.builder(
            controller: ModalScrollController.of(context),
            physics: BouncingScrollPhysics(),
            reverse: false,
            itemCount: snapshot.data.data.length,
            itemBuilder: (BuildContext context, int index) {
              final screenSize = MediaQuery.of(context).size;
              return Container(
                margin: EdgeInsets.only(top: 0.0, bottom: 0),
                child: Transform(
                  transform: Matrix4.translationValues(-6, 0.0, 0.0),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: new BorderRadius.circular(30.0),
                      child: GestureDetector(
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StorytellerProfile(
                                  snapshot.data.data[index].from.user.id,
                                  false,
                                  refresh),
                            ),
                          ),
                        },
                        child: CachedNetworkImage(
                          height: kToolbarHeight / 1.3,
                          width: kToolbarHeight / 1.3,
                          fit: BoxFit.cover,
                          imageUrl:
                              (snapshot.data.data[index].from.user.avatar),
                        ),
                      ),
                    ),
                    title: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(children: [
                            Container(
                              width: screenSize.width - 155,
                              child: new Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: screenSize.width - 155,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        margin: const EdgeInsets.only(
                                          left: 0.0,
                                          top: 0,
                                          bottom: 5,
                                          right: 0.0,
                                        ),
                                        child: new Column(
                                          children: <Widget>[
                                            RichText(
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                              maxLines: 23,
                                              text: TextSpan(
                                                text: snapshot.data.data[index]
                                                        .from.user.name +
                                                    ' ',
                                                style: TextStyle(
                                                  fontFamily:
                                                      "SFProDisplayBold",
                                                  fontSize: 14.6,
                                                  color: Color.fromRGBO(
                                                      28, 28, 28, 1),
                                                ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: snapshot.data
                                                        .data[index].comment,
                                                    style: TextStyle(
                                                      fontFamily:
                                                          "SFProDisplayMedium",
                                                      fontSize: 14.6,
                                                      color: Color.fromRGBO(
                                                          28, 28, 28, 1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ]),
                        ]),
                    subtitle: Row(
                      children: [
                        Text(
                          timeago
                              .format(
                                  DateTime.parse(
                                          snapshot.data.data[index].createdAt)
                                      .toLocal(),
                                  locale: AppLocalizations.instance.mlangCode)
                              .replaceAll("ago", "")
                              .replaceAll("moment", "few seconds")
                              .replaceAll("minute", "m")
                              .replaceAll("hour", "h")
                              .replaceAll("day", "d")
                              .replaceAll("s", ""),
                          style: TextStyle(
                            fontFamily: "SFProDisplayRegular",
                            fontSize: 13,
                            color: Color.fromRGBO(152, 152, 152, 1),
                          ),
                        ),
                        SizedBox(
                          width: 10.5,
                        ),
                        snapshot.data.data[index].from.user.id == global.userId
                            ? GestureDetector(
                                onTap: () {
                                  bloc.deleteComment(
                                      snapshot.data.data[index].id);
                                },
                                child: Text(
                                  '|   ' +
                                      AppLocalizations.instance.text('delete1'),
                                  style: TextStyle(
                                    fontFamily: "SFProDisplayRegular",
                                    fontSize: 13,
                                    color: Color.fromRGBO(152, 152, 152, 1),
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                    trailing: Transform(
                      transform: Matrix4.translationValues(6, 0.0, 0.0),
                      child: GestureDetector(
                        onTap: () {
                          Vibrate.feedback(FeedbackType.medium);

                          if (snapshot.data.data[index].isLike == "true") {
                            bloc.unlike(
                                global.userId, snapshot.data.data[index].id);
                          } else {
                            bloc.like(
                                global.userId, snapshot.data.data[index].id);
                          }
                        },
                        child: Column(children: <Widget>[
                          SizedBox(height: 5),
                          snapshot.data.data[index].isLike == "true"
                              ? Icon(Icons.favorite,
                                  color: Colors.red, size: 22)
                              : Icon(
                                  Icons.favorite_border,
                                  size: 22,
                                  color: Color.fromRGBO(79, 79, 79, 1),
                                ),
                          Container(
                            padding: const EdgeInsets.only(
                              left: 1,
                            ),
                            child: Text(
                              snapshot.data.data[index].like == 1 ||
                                      snapshot.data.data[index].like == 0
                                  ? '${snapshot.data.data[index].like}'
                                  : '${snapshot.data.data[index].like}',
                              style: TextStyle(
                                fontFamily: "SFProDisplayBold",
                                fontSize: 13,
                                color: Color.fromRGBO(79, 79, 79, 1),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                padding: null,
              );
            },
          ),
        ),
        Positioned(
          right: 19.0,
          bottom: 20.5,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                color: Color.fromRGBO(224, 224, 224, 1),
              ),
              color: Colors.white,
            ),
            child: KeyboardDismisser(
              gestures: [GestureType.onVerticalDragDown, GestureType.onTap],
              child: Container(
                transform: Matrix4.translationValues(-8.5, -7.5, 0.0),
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(ico.MaterialCommunityIcons.chevron_down),
                  iconSize: 30.0,
                  color: Color.fromRGBO(79, 79, 79, 1),
                  onPressed: () {
                    Vibrate.feedback(FeedbackType.medium);
                    showWidget();
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 60.0,
          bottom: 78,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                color: Color.fromRGBO(224, 224, 224, 1),
              ),
              color: Colors.white,
            ),
            child: Container(
              transform: Matrix4.translationValues(-3.5, -5, 0.0),
              child: IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: Icon(ico.Entypo.emoji_flirt),
                iconSize: 20.0,
                color: Color.fromRGBO(79, 79, 79, 1),
                onPressed: () {
                  Vibrate.feedback(FeedbackType.medium);
                  showWidget();
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 0.0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color.fromRGBO(224, 224, 224, 1),
                  width: 0.8,
                ),
              ),
            ),
            width: screenSize.width,
            height: bottomBarHeight + 75,
          ),
        ),
        Positioned(
          left: 15.0,
          bottom: bottomBarHeight + 12,
          right: 15.0,
          child: Container(
            //height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                color: Color.fromRGBO(224, 224, 224, 1),
              ),
              color: Colors.white,
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.only(left: 60),
                    child: TextField(
                      onTap: () {
                        // hideWidget();
                      },
                      autofocus: false,
                      maxLines: null,
                      enableInteractiveSelection: true,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {},
                      controller: commentController,
                      decoration: InputDecoration.collapsed(
                        hintText: AppLocalizations.instance.text('addcomm'),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  // height: 18.0,
                  width: 75.0,
                  child: IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: Text(
                      AppLocalizations.instance.text('send'),
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: "SFProDisplayBold",
                        // fontSize: 33.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    iconSize: 28.0,
                    color: Colors.blue,
                    onPressed: () async {
                      var message = Data.add(global.userId,
                          widget.toPostIdController, commentController.text);
                      await bloc.saveComment(message);
                      commentController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 19.0,
          bottom: bottomBarHeight + 16,
          child: CircleAvatar(
            radius: 21,
            backgroundImage: new CachedNetworkImageProvider(
              (global.avatar),
            ),
          ),
        ),
        Visibility(
          visible: widgetVisible,
          child: Positioned(
            bottom: bottomBarHeight + 66,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color.fromRGBO(224, 224, 224, 1),
                    width: 0.8,
                  ),
                ),
              ),
              width: screenSize.width,
              padding: EdgeInsets.only(
                top: 7.0,
                bottom: 5,
              ),
              child: Row(children: <Widget>[
                SizedBox(width: 11),
                GestureDetector(
                  onTap: () {
                    smile();
                  },
                  child: Text(
                    " 😍 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile2();
                  },
                  child: Text(
                    "😊 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile3();
                  },
                  child: Text(
                    "🤤 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile4();
                  },
                  child: Text(
                    "😂 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile5();
                  },
                  child: Text(
                    "😎 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile6();
                  },
                  child: Text(
                    "🤩 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile7();
                  },
                  child: Text(
                    "👍 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile8();
                  },
                  child: Text(
                    "👏 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
                SizedBox(width: 7),
                GestureDetector(
                  onTap: () {
                    smile9();
                  },
                  child: Text(
                    "🤟 ",
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  await(Future<ConnectivityResult> checkConnectivity) {}
}
