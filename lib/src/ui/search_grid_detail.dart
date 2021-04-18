import 'package:Storyteller/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import '../blocs/search_main_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/image_model.dart';
import 'package:Storyteller/src/ui/profile.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'dart:async';
import 'package:mime/mime.dart';
import 'globals.dart' as global;
import 'package:flutter_icons/flutter_icons.dart' as ico;
import 'dart:math' as math;
import 'package:Storyteller/src/ui/comments.dart';
import 'package:Storyteller/src/ui/video.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:progress_indicators/progress_indicators.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:Storyteller/src/resources/firebase_service.dart';

class SearchTabPhoto extends StatefulWidget {
  final int index_photo;
  SearchTabPhoto(this.index_photo, {Key key}) : super(key: key);
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<SearchTabPhoto>
    with AutomaticKeepAliveClientMixin {
  Timer _timer;
  FirebaseService _fservice = new FirebaseService();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
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
          bloc.fetchPhoto(controller.text);
          bloc.photoFetcherStatusSearch.listen((onData) {
            bloc.fetchPhoto(controller.text);
          });
        }
      },
    );
  }

  void savedShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: new Text(
            AppLocalizations.instance.text('seccessreport'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15.0,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Container(
            padding: EdgeInsets.only(top: 40.0),
            child: Icon(
              Icons.check_circle,
              size: 66,
              color: Color.fromRGBO(9, 214, 63, 1),
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                AppLocalizations.instance.text('close'),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void likeShow() {
    showDialog(
        barrierColor: Colors.black.withOpacity(0.30),
        barrierDismissible: false,
        context: context,
        builder: (BuildContext builderContext) {
          _timer = Timer(Duration(milliseconds: 400), () {
            Navigator.of(context).pop();
          });

          return Container(
              height: 150,
              width: 150,
              color: Colors.transparent,
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(900.0),
                ),
                title: Container(
                  height: 150,
                  width: 150,
                  // padding: EdgeInsets.only(top: 40.0, bottom: 40),
                  child: HeartbeatProgressIndicator(
                    child: Icon(
                      Icons.favorite,
                      size: 50,
                      color: Color.fromRGBO(255, 255, 255, 0.85),
                    ),
                  ),
                ),
              ));
        }).then((val) {
      if (_timer.isActive) {
        _timer.cancel();
      }
    });
  }

  void _onRefresh() async {
    Vibrate.feedback(FeedbackType.medium);
    // monitor network fetch
    await bloc.fetchPhoto(controller.text);
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  bool isBlock(int id) {
    var blocklist = global.blockList.split(",");
    print(blocklist);
    return blocklist.contains(id.toString());
  }

  bool isBlocked(String list) {
    var id = global.userId;
    var blocklist = list.split(",");
    return blocklist.contains(id.toString());
  }

  refresh() {}

  refreshFilter() {
    setState(() {});
  }

  TextEditingController controller = new TextEditingController();
  bool hasSearchEntry = false;

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

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: [
        Scaffold(
           appBar: AppBar(
              leading: Container(
                transform: Matrix4.translationValues(5.0, 0.0, 0.0),
                padding: EdgeInsets.only(left: 10.0, bottom: 0),
                child: BackButton(),
              ),
              elevation: 1.0,
              centerTitle: true,
          title: Text(
                  AppLocalizations.instance.text('search'),
                  style: TextStyle(
                    fontFamily: 'SFProDisplayBold',
                    fontSize: 23.5,
                  ),
                ),
           ),
          body: buildMyList(),
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

  Widget buildMyList() {
    final screenSize = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: bloc.allPhotos,
      builder: (context, AsyncSnapshot<ImageModel> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.datas.length == 0) {
            return Center(
              child: Text("No Posts"),
            );
          } else {
            return SmartRefresher(
              enablePullDown: true,
              header: ClassicHeader(),
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: ListView.builder(
                addAutomaticKeepAlives: true,
                physics: BouncingScrollPhysics(),
                itemCount: snapshot.data.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return (isBlock(snapshot.data.data[index].user.data.id) ==
                              true) ||
                          (isBlocked(
                                  snapshot.data.data[index].user.data.block) ==
                              true)
                      ? Container()
                      : index < widget.index_photo
                          ? SizedBox()
                          : Column(
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: new BorderRadius.circular(0.0),
                                  child:
                                       new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                  new GestureDetector(
                                                    onTap: () => {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              StorytellerProfile(
                                                                  snapshot
                                                                      .data
                                                                      .data[
                                                                          index]
                                                                      .user
                                                                      .data
                                                                      .id,
                                                                  false,
                                                                  refresh),
                                                        ),
                                                      ),
                                                    },
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 15.0,
                                                          right: 15.0,
                                                          bottom: 10.0,
                                                          top: 15.0),
                                                      child: Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                new BorderRadius
                                                                        .circular(
                                                                    30.0),
                                                            child:
                                                                CachedNetworkImage(
                                                              height:
                                                                  kToolbarHeight /
                                                                      1.35,
                                                              width:
                                                                  kToolbarHeight /
                                                                      1.35,
                                                              fit: BoxFit.cover,
                                                              placeholder:
                                                                  (c, d) {
                                                                return Center(
                                                                  child:
                                                                      SizedBox(
                                                                    height:
                                                                        kToolbarHeight /
                                                                            1.35,
                                                                    width:
                                                                        kToolbarHeight /
                                                                            1.35,
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          new BorderRadius.circular(
                                                                              100.0),
                                                                      child:
                                                                          Shimmer(
                                                                        duration:
                                                                            Duration(seconds: 1), //Default value
                                                                        interval:
                                                                            Duration(seconds: 1), //Default value: Duration(seconds: 0)
                                                                        color: Colors
                                                                            .black, //Default value
                                                                        enabled:
                                                                            true, //Default value
                                                                        direction:
                                                                            ShimmerDirection.fromLTRB(), //Default Value
                                                                        child:
                                                                            Container(
                                                                          width:
                                                                              110,
                                                                          height:
                                                                              190,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.black12,
                                                                            borderRadius:
                                                                                new BorderRadius.circular(100),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              imageUrl: snapshot
                                                                  .data
                                                                  .data[index]
                                                                  .user
                                                                  .data
                                                                  .avatar,
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              SizedBox(
                                                                width: 10.0,
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: <
                                                                    Widget>[
                                                                  Row(
                                                                    children: [
                                                                      new Text(
                                                                        snapshot
                                                                            .data
                                                                            .data[index]
                                                                            .user
                                                                            .data
                                                                            .name,
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              "SFProDisplayBold",
                                                                          fontSize:
                                                                              15.5,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      snapshot.data.data[index].user.data.badge ==
                                                                              'true'
                                                                          ? Container(
                                                                              padding: EdgeInsets.only(top: 1.5),
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(0),
                                                                                child: Icon(Icons.check_circle, size: 13.5, color: Colors.blue),
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                    height: 2.0,
                                                                  ),
                                                                  new Text(
                                                                    timeago.format(
                                                                        DateTime.parse(snapshot.data.data[index].createdat)
                                                                            .toLocal(),
                                                                        locale: AppLocalizations
                                                                            .instance
                                                                            .mlangCode),
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          "SFProDisplayRegular",
                                                                      fontSize:
                                                                          13.5,
                                                                      color: Color.fromRGBO(
                                                                          152,
                                                                          152,
                                                                          152,
                                                                          1),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  MaterialButton(
                                                    height: 20.0,
                                                    minWidth: 65.0,
                                                    child: const Icon(
                                                        LineIcons.ellipsis_h),
                                                    onPressed: () {
                                                      showModalBottomSheet<
                                                          dynamic>(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        isScrollControlled:
                                                            true,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15.0)),
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Wrap(
                                                              children: <
                                                                  Widget>[
                                                                Container(
                                                                  decoration: new BoxDecoration(
                                                                      color: Colors
                                                                          .transparent,
                                                                      borderRadius: new BorderRadius
                                                                              .only(
                                                                          topLeft: const Radius.circular(
                                                                              30.0),
                                                                          topRight:
                                                                              const Radius.circular(30.0))),
                                                                  child:
                                                                      Container(
                                                                    child:
                                                                        Column(
                                                                      children: <
                                                                          Widget>[
                                                                        new Column(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.center,
                                                                            children: [
                                                                              Container(
                                                                                  width: screenSize.width - 45,
                                                                                  decoration: BoxDecoration(
                                                                                    borderRadius: BorderRadius.circular(10),
                                                                                    color: Colors.white,
                                                                                  ),
                                                                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                                                    ButtonTheme(
                                                                                      minWidth: screenSize.width - 45.8,
                                                                                      height: 56.0,
                                                                                      child: FlatButton(
                                                                                        // splashColor: Colors.transparent,
                                                                                        // highlightColor: Colors.transparent,
                                                                                        child: Text(
                                                                                          AppLocalizations.instance.text('reportpost'),
                                                                                          style: TextStyle(color: Colors.red, fontSize: 16.3, fontFamily: 'SFProDisplayMedium'),
                                                                                        ),
                                                                                        color: Colors.transparent,
                                                                                        shape: new RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(10.0), topLeft: Radius.circular(10.0))),
                                                                                        onPressed: () {
                                                                                          print(snapshot.data.data[index].id);
                                                                                          bloc.reportpost(snapshot.data.data[index].id);
                                                                                          Navigator.pop(context);
                                                                                          savedShow();
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                    const Divider(
                                                                                      color: Color.fromRGBO(224, 224, 224, 1),
                                                                                      height: 1,
                                                                                      thickness: 0,
                                                                                      indent: 0,
                                                                                      endIndent: 0,
                                                                                    ),
                                                                                    ButtonTheme(
                                                                                      minWidth: screenSize.width - 45.8,
                                                                                      height: 56.0,
                                                                                      child: FlatButton(
                                                                                        //splashColor: Colors.transparent,
                                                                                        // highlightColor: Colors.transparent,
                                                                                        child: Text(
                                                                                          AppLocalizations.instance.text('visitprofile'),
                                                                                          style: TextStyle(color: Colors.black, fontSize: 16.3, fontFamily: 'SFProDisplayMedium'),
                                                                                        ),
                                                                                        color: Colors.transparent,
                                                                                        shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(0.0)),
                                                                                        onPressed: () {
                                                                                          Navigator.pop(context);
                                                                                          Navigator.push(
                                                                                            context,
                                                                                            MaterialPageRoute(
                                                                                              builder: (context) => StorytellerProfile(snapshot.data.data[index].user.data.id, false, refresh),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                    const Divider(
                                                                                      color: Color.fromRGBO(224, 224, 224, 1),
                                                                                      height: 1,
                                                                                      thickness: 0,
                                                                                      indent: 0,
                                                                                      endIndent: 0,
                                                                                    ),
                                                                                    ButtonTheme(
                                                                                      minWidth: screenSize.width - 45.8,
                                                                                      height: 56.0,
                                                                                      child: FlatButton(
                                                                                        //splashColor: Colors.transparent,
                                                                                        // highlightColor: Colors.transparent,
                                                                                        child: Text(
                                                                                          AppLocalizations.instance.text('share'),
                                                                                          style: TextStyle(color: Colors.black, fontSize: 16.3, fontFamily: 'SFProDisplayMedium'),
                                                                                        ),
                                                                                        color: Colors.transparent,
                                                                                        shape: new RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(10.0), bottomLeft: Radius.circular(10.0))),
                                                                                        onPressed: () {
                                                                                          Navigator.pop(context);
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  ]))
                                                                            ]),
                                                                        Container(
                                                                            height:
                                                                                10),
                                                                        ButtonTheme(
                                                                          minWidth:
                                                                              screenSize.width - 45.8,
                                                                          height:
                                                                              56.0,
                                                                          child: FlatButton(
                                                                              child: Text(
                                                                                AppLocalizations.instance.text('cancel'),
                                                                                style: TextStyle(color: Colors.black, fontSize: 16.3, fontFamily: 'SFProDisplayMedium'),
                                                                              ),
                                                                              color: Colors.white,
                                                                              shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
                                                                              onPressed: () {
                                                                                Navigator.pop(context);
                                                                              }),
                                                                        ),
                                                                        Container(
                                                                            height:
                                                                                40),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )
                                                              ]);
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ])
                                         
                                ),
                                GestureDetector(
                                  onDoubleTap: () {
                                    (snapshot.data.data[index].like == "true")
                                        ? bloc.unlikepost(
                                            snapshot.data.data[index].id)
                                        : bloc.likepost(
                                            snapshot.data.data[index].id);
                                    Vibrate.feedback(FeedbackType.medium);
                                    likeShow();
                                    _fservice.saveUserPostLikeFirestore(
                                        snapshot.data.data[index].userid);
                                  },
                                  child: new Container(
                                    child: Stack(children: <Widget>[
                                      new Container(
                                        padding: EdgeInsets.only(
                                          left: 0,
                                          right: 0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              new BorderRadius.circular(0.0),
                                          child: checkFileType(snapshot.data
                                                      .data[index].image) ==
                                                  "image"
                                              ? PinchZoomImage(
                                                  image: CachedNetworkImage(
                                                    width: screenSize.width,
                                                    placeholder: (c, d) {
                                                      return Container(
                                                        height: 300,
                                                        width: screenSize.width,
                                                      );
                                                    },
                                                    fit: BoxFit.cover,
                                                    imageUrl: snapshot
                                                        .data.data[index].image,
                                                  ),
                                                  zoomedBackgroundColor:
                                                      Color.fromRGBO(
                                                          240, 240, 240, 0.50),
                                                )
                                              : VideoClip(
                                              url: snapshot
                                                  .data.data[index].image,
                                            ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                SizedBox(
                                  height: 0.0,
                                ),
                                ClipRRect(
                                  borderRadius: new BorderRadius.circular(0.0),
                                  child:  Container(
                                          padding: const EdgeInsets.only(
                                              bottom: 0.0),
                                          child: new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: screenSize.width,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    padding:
                                                        const EdgeInsets.only(
                                                      left: 16.0,
                                                      top: 13,
                                                      bottom: 13,
                                                      right: 16.0,
                                                    ),
                                                    child: new Column(
                                                      children: <Widget>[
                                                        RichText(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                          maxLines: 3,
                                                          text: TextSpan(
                                                            text: snapshot
                                                                    .data
                                                                    .data[index]
                                                                    .user
                                                                    .data
                                                                    .name +
                                                                ' ',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  "SFProDisplayBold",
                                                              fontSize: 13.7,
                                                              color: Color
                                                                  .fromRGBO(
                                                                      28,
                                                                      28,
                                                                      28,
                                                                      1),
                                                            ),
                                                            children: <
                                                                TextSpan>[
                                                              TextSpan(
                                                                text: snapshot
                                                                    .data
                                                                    .data[index]
                                                                    .description,
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      "SFProDisplayMedium",
                                                                  fontSize:
                                                                      13.7,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          28,
                                                                          28,
                                                                          28,
                                                                          1),
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
                                        )
                                      
                                ),
                                ClipRRect(
                                  borderRadius: new BorderRadius.circular(0.0),
                                  child:
                                      Container(
                                              child: Column(children: [
                                              Container(
                                                padding: const EdgeInsets.only(
                                                    bottom: 0.0),
                                                child: const Divider(
                                                  color: Color.fromRGBO(
                                                      207, 207, 207, 1),
                                                  height: 1,
                                                  thickness: 0,
                                                  indent: 16,
                                                  endIndent: 16,
                                                ),
                                              ),
                                              Center(
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Container(
                                                          height: 42,
                                                          child: FlatButton(
                                                            splashColor: Colors
                                                                .transparent,
                                                            highlightColor:
                                                                Colors
                                                                    .transparent,
                                                            child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: <
                                                                    Widget>[
                                                                  (snapshot.data.data[index].like ==
                                                                          "true")
                                                                      ? Icon(
                                                                          Icons
                                                                              .favorite,
                                                                          color: Colors
                                                                              .red,
                                                                          size:
                                                                              23)
                                                                      : Icon(
                                                                          Icons
                                                                              .favorite_border,
                                                                          size:
                                                                              23,
                                                                          color: Color.fromRGBO(
                                                                              79,
                                                                              79,
                                                                              79,
                                                                              1),
                                                                        ),
                                                                  SizedBox(
                                                                    width: 5.0,
                                                                  ),
                                                                  Text(
                                                                    snapshot
                                                                            .data
                                                                            .data[
                                                                                index]
                                                                            .likecount
                                                                            .toString() +
                                                                        ' ' +
                                                                        AppLocalizations
                                                                            .instance
                                                                            .text('like'),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          "SFProDisplayMedium",
                                                                      fontSize:
                                                                          14.5,
                                                                      color: Color
                                                                          .fromRGBO(
                                                                              79,
                                                                              79,
                                                                              79,
                                                                              1),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            onPressed: () {
                                                              Vibrate.feedback(
                                                                  FeedbackType
                                                                      .medium);
                                                              likeShow();
                                                              (snapshot
                                                                          .data
                                                                          .data[
                                                                              index]
                                                                          .like ==
                                                                      "true")
                                                                  ? bloc.unlikepost(
                                                                      snapshot
                                                                          .data
                                                                          .data[
                                                                              index]
                                                                          .id)
                                                                  : bloc.likepost(
                                                                      snapshot
                                                                          .data
                                                                          .data[
                                                                              index]
                                                                          .id);
                                                              _fservice.saveUserPostLikeFirestore(
                                                                  snapshot
                                                                      .data
                                                                      .data[
                                                                          index]
                                                                      .userid);
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        height: 42,
                                                        child: FlatButton(
                                                          splashColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                Transform(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  transform: Matrix4
                                                                      .rotationY(
                                                                          math.pi),
                                                                  child: Icon(
                                                                      ico.Feather
                                                                          .message_circle,
                                                                      color: Color
                                                                          .fromRGBO(
                                                                              79,
                                                                              79,
                                                                              79,
                                                                              1),
                                                                      size:
                                                                          21.7),
                                                                ),
                                                                SizedBox(
                                                                  width: 5.0,
                                                                ),
                                                                Center(
                                                                  child: Text(
                                                                    snapshot
                                                                            .data
                                                                            .data[
                                                                                index]
                                                                            .commentcount
                                                                            .toString() +
                                                                        ' ' +
                                                                        AppLocalizations
                                                                            .instance
                                                                            .text('comments'),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          "SFProDisplayMedium",
                                                                      fontSize:
                                                                          14.5,
                                                                      color: Color
                                                                          .fromRGBO(
                                                                              79,
                                                                              79,
                                                                              79,
                                                                              1),
                                                                    ),
                                                                  ),
                                                                )
                                                              ]),
                                                          onPressed: () {
                                                            showCupertinoModalBottomSheet(
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                elevation: 0.90,
                                                                isDismissible:
                                                                    true,
                                                                barrierColor: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.20),
                                                                enableDrag:
                                                                    true,
                                                                expand: false,
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        ConstrainedBox(
                                                                          constraints:
                                                                              new BoxConstraints(
                                                                            minHeight:
                                                                                screenSize.height - 120,
                                                                            maxHeight:
                                                                                screenSize.height - 120,
                                                                          ),
                                                                          child: Comments(snapshot
                                                                              .data
                                                                              .data[index]
                                                                              .id),
                                                                        ));
                                                          },
                                                        ),
                                                      ),
                                                      Expanded(
                                                          child: Container(
                                                        height: 42,
                                                        child: FlatButton(
                                                          splashColor: Colors
                                                              .transparent,
                                                          highlightColor: Colors
                                                              .transparent,
                                                          child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                snapshot
                                                                            .data
                                                                            .data[
                                                                                index]
                                                                            .saved !=
                                                                        "true"
                                                                    ? Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment
                                                                                .center,
                                                                        children: [
                                                                            Icon(Icons.bookmark_border,
                                                                                color: Color.fromRGBO(79, 79, 79, 1),
                                                                                size: 22.6),
                                                                            SizedBox(
                                                                              width: 5.0,
                                                                            ),
                                                                            Text(
                                                                              AppLocalizations.instance.text('save'),
                                                                              textAlign: TextAlign.start,
                                                                              style: TextStyle(
                                                                                fontFamily: "SFProDisplayMedium",
                                                                                fontSize: 14.5,
                                                                                color: Color.fromRGBO(79, 79, 79, 1),
                                                                              ),
                                                                            ),
                                                                          ])
                                                                    : Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                            Icon(Icons.bookmark,
                                                                                color: Color.fromRGBO(78, 187, 31, 1),
                                                                                size: 22.6),
                                                                            SizedBox(
                                                                              width: 5.0,
                                                                            ),
                                                                            Text(
                                                                              AppLocalizations.instance.text('savedposticon'),
                                                                              textAlign: TextAlign.start,
                                                                              style: TextStyle(
                                                                                fontFamily: "SFProDisplayMedium",
                                                                                fontSize: 14.5,
                                                                                color: Color.fromRGBO(79, 79, 79, 1),
                                                                              ),
                                                                            ),
                                                                          ]),
                                                              ]),
                                                          onPressed: () {
                                                            Vibrate.feedback(
                                                                FeedbackType
                                                                    .medium);
                                                            (snapshot
                                                                        .data
                                                                        .data[
                                                                            index]
                                                                        .saved ==
                                                                    "true")
                                                                ? bloc.removePost(snapshot
                                                                        .data
                                                                        .data[
                                                                            index]
                                                                        .id) +
                                                                    Scaffold.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        padding: EdgeInsets.only(
                                                                            bottom:
                                                                                5,
                                                                            top:
                                                                                5),
                                                                        margin: EdgeInsets.only(
                                                                            bottom:
                                                                                13,
                                                                            left:
                                                                                13,
                                                                            right:
                                                                                13),
                                                                        elevation:
                                                                            0,
                                                                        backgroundColor: Color.fromRGBO(
                                                                            78,
                                                                            187,
                                                                            31,
                                                                            1),
                                                                        content:
                                                                            Text(
                                                                          AppLocalizations
                                                                              .instance
                                                                              .text('removesaved'),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w500),
                                                                        ),
                                                                        duration:
                                                                            Duration(milliseconds: 1300),
                                                                        behavior:
                                                                            SnackBarBehavior.floating,
                                                                      ),
                                                                    )
                                                                : bloc.savePost(snapshot
                                                                        .data
                                                                        .data[
                                                                            index]
                                                                        .id) +
                                                                    Scaffold.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        padding: EdgeInsets.only(
                                                                            bottom:
                                                                                5,
                                                                            top:
                                                                                5),
                                                                        margin: EdgeInsets.only(
                                                                            bottom:
                                                                                13,
                                                                            left:
                                                                                13,
                                                                            right:
                                                                                13),
                                                                        elevation:
                                                                            0,
                                                                        backgroundColor: Color.fromRGBO(
                                                                            78,
                                                                            187,
                                                                            31,
                                                                            1),
                                                                        content:
                                                                            Text(
                                                                          AppLocalizations
                                                                              .instance
                                                                              .text('postaddsave'),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w500),
                                                                        ),
                                                                        duration:
                                                                            Duration(milliseconds: 1300),
                                                                        behavior:
                                                                            SnackBarBehavior.floating,
                                                                      ),
                                                                    );
                                                          },
                                                        ),
                                                      )),
                                                    ]),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: const Divider(
                                                  color: Color.fromRGBO(
                                                      207, 207, 207, 1),
                                                  height: 1,
                                                  thickness: 0,
                                                  indent: 0,
                                                  endIndent: 0,
                                                ),
                                              ),
                                            ]))
                                         
                                ),
                              ],
                            );
                },
              ),
            );
          }
        } else if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        );
      },
    );
  }

  Future onSearchTextChanged(String value) async {
    bloc.fetchPhoto(value);
    setState(() {
      hasSearchEntry = value.isNotEmpty;
    });
  }
}
