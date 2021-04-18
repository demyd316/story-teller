import 'package:Storyteller/app_localizations.dart';
import 'package:Storyteller/src/ui/stories_page.dart';
import 'package:Storyteller/src/ui/video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:Storyteller/src/models/image_model.dart';
import 'package:Storyteller/src/models/user_model.dart';
import 'package:Storyteller/src/ui/profile.dart';
import 'package:Storyteller/src/ui/start_live.dart';
import 'package:Storyteller/src/ui/add_tab_photo.dart';
import 'package:Storyteller/src/ui/add_tab_video.dart';
import 'package:Storyteller/src/ui/stories_preview.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'conversation_list.dart';
import 'package:line_icons/line_icons.dart';
import '../blocs/photos_bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Storyteller/src/ui/add_photo.dart';
import 'dart:convert';
import 'package:Storyteller/src/constant/utils.dart';
import 'package:mime/mime.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'globals.dart' as global;
import 'package:flutter_icons/flutter_icons.dart' as ico;
import 'dart:math' as math;
import 'package:Storyteller/src/ui/comments.dart';
import 'package:Storyteller/src/ui/covid19.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:page_transition/page_transition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:async/async.dart';
import 'package:Storyteller/src/constant/httpService.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart' as trans;
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:Storyteller/src/resources/firebase_service.dart';

class PhotoFeed extends StatefulWidget {
  @override
  PhotoFeed({Key key}) : super(key: key);

  State<StatefulWidget> createState() {
    return NewsFeedState();
  }
}

class NewsFeedState extends State<PhotoFeed>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  ScrollController _scrollController;
  Animation gap;
  Animation base;
  Animation reverse;
  AnimationController controller;
  File _media;
  bool isVideo = false;
  bool lastStatus = true;

  final double targetElevation = 0.6;
  double _elevation = 0;
  ScrollController _controllers;
  VideoPlayerController _controller;
  Duration _duration;
  StreamSubscription connectivitySubscription;
  Timer _timer, timer;

  final FlareControls flareControls = FlareControls();
  bool isLiked = false;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  FirebaseService _fservice = new FirebaseService();

  @override
  bool get wantKeepAlive => true;

  _scrollListener() {
    if (isShrink != lastStatus) {
      setState(() {
        lastStatus = isShrink;
      });
    }
  }

  bool get isShrink {
    return _scrollController.hasClients &&
        _scrollController.offset > (50 - kToolbarHeight);
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

  Future<NewsFeedState> _buildList;

  bool auto = false;
  bool user = true;

  @override
  void initState() {
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

    // _buildList = NewsFeedState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(seconds: 4));
    base = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    reverse = Tween<double>(begin: 0.0, end: -1.0).animate(base);
    gap = Tween<double>(begin: 3.0, end: 0.0).animate(base)
      ..addListener(() {
        setState(() {});
      });
    controller.forward();

    _controllers = ScrollController();
    _controllers.addListener(_scrollListeners);
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
          bloc.fetchAllPhoto();
          bloc.photoFetcherStatus.listen((onData) {
            bloc.fetchAllPhoto();
          });
        }
      },
    );

    const oneSec = const Duration(milliseconds: 2000);
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
              bloc.fetchStoryList();
              bloc.dispose();
            }
          },
        );
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

  Future<AudioPlayer> playLocalAsset() async {
    AudioCache cache = new AudioCache();
    return await cache.play("hm.mp3");
  }

  void _onRefresh() async {
    Vibrate.feedback(FeedbackType.medium);
    // monitor network fetch
    await bloc.fetchAllPhoto();
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  refresh() {}

  @override
  void dispose() {
    controller.dispose();
    bloc.dispose();
    super.dispose();

    _controllers?.removeListener(_scrollListeners);
    _controllers?.dispose();
  }

  void savedShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: new Text(
            AppLocalizations.instance.text('successreport'),
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

  void sendUploadFile() async {
    final String url =
        "${NetworkUtils.urlBase}${NetworkUtils.serverApi}stories";

    var request = new http.MultipartRequest("POST", Uri.parse(url));
    print(url);
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ' + await fetchToken(),
    };

    var stream_video =
        new http.ByteStream(DelegatingStream.typed(_media.openRead()));
    var length_video = await _media.length();

    print(path.basename(_media.path));
    print(length_video);

    var multipartFile = new http.MultipartFile(
        'media', stream_video, length_video,
        filename: path.basename(_media.path));

    request.files.add(multipartFile);
    if (isVideo == true) {
      request.fields['duration'] = _duration.toString();
      request.fields['type'] = 'video';
    } else {
      request.fields['duration'] = '5';
      request.fields['type'] = 'image';
    }

    request.headers.addAll(headers);
    var response = await request.send();
    print(response.statusCode);

    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }

  Future<String> fetchToken() async {
    var client = await HttpService().getClient();
    return client.credentials.accessToken.toString();
  }

  checkFileType(String url) {
    String mimeStr = lookupMimeType(url);
    var fileType = mimeStr.split('/');
    print(fileType[0]);
    return fileType[0];
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        maxWidth: 1000,
        maxHeight: 1920,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                //CropAspectRatioPreset.ratio3x2,
                //CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio16x9
              ]
            : [
                // CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,

                //CropAspectRatioPreset.ratio7x5,
                // CropAspectRatioPreset.ratio16x9
              ],
        iosUiSettings: IOSUiSettings(
          //title: 'Crop Image',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          rectX: 1,
          rectY: 1,
          rectWidth: 1000,
          rectHeight: 1920,
          hidesNavigationBar: true,
          resetButtonHidden: true,
          minimumAspectRatio: 1.0,
          // rotateClockwiseButtonHidden: true,
        ));
    if (croppedImage != null) {
      _media = croppedImage;
      Navigator.pop(context);
      setState(() {});
      sendUploadFile();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          padding: EdgeInsets.only(bottom: 5, top: 5),
          margin: EdgeInsets.only(bottom: 13, left: 13, right: 13),
          elevation: 0,
          backgroundColor: Color.fromRGBO(78, 187, 31, 1),
          content: Text(
            AppLocalizations.instance.text('storyupload'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void checkLiveType() {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Column(children: <Widget>[
              SizedBox(height: 5),
              Text(
                'Live',
                style: TextStyle(
                  fontFamily: 'SFProDisplayBold',
                  fontSize: 20.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]),
          ),
          content: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppLocalizations.instance.text('livedescription'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontFamily: 'SFProDisplayMedium',
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),
                const Divider(
                  color: Color.fromRGBO(224, 224, 224, 1),
                  height: 1,
                  thickness: 0,
                  indent: 0,
                  endIndent: 0,
                ),
                ButtonTheme(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  minWidth: screenSize.width,
                  height: 20.0,
                  child: FlatButton(
                    //splashColor: Colors.transparent,
                    //highlightColor: Colors.transparent,
                    child: Text(
                      AppLocalizations.instance.text('close'),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.3,
                          fontFamily: 'SFProDisplayMedium'),
                    ),
                    color: Colors.transparent,
                    shape: new RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(0.0),
                            topLeft: Radius.circular(0.0))),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  void checkMediaType() {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Column(children: <Widget>[
              AvatarGlow(
                glowColor: Color.fromRGBO(75, 9, 219, 1),
                endRadius: 55.0,
                duration: Duration(milliseconds: 1800),
                repeat: true,
                showTwoGlows: true,
                repeatPauseDuration: Duration(milliseconds: 50),
                child: Container(
                    decoration: new BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    width: 50,
                    height: 50,
                    transform: Matrix4.translationValues(0.0, 0.0, 0.0),
                    child: Icon(LineIcons.plus, size: 45)),
              ),
              SizedBox(height: 5),
              Text(
                AppLocalizations.instance.text('uploadstory'),
                style: TextStyle(
                  fontFamily: 'SFProDisplayBold',
                  fontSize: 20.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]),
          ),
          content: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppLocalizations.instance.text('storyselect'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontFamily: 'SFProDisplayMedium',
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),
                const Divider(
                  color: Color.fromRGBO(224, 224, 224, 1),
                  height: 1,
                  thickness: 0,
                  indent: 0,
                  endIndent: 0,
                ),
                ButtonTheme(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  minWidth: screenSize.width,
                  height: 45.0,
                  child: FlatButton(
                    //splashColor: Colors.transparent,
                    //highlightColor: Colors.transparent,
                    child: Text(
                      AppLocalizations.instance.text('image'),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.3,
                          fontFamily: 'SFProDisplayMedium'),
                    ),
                    color: Colors.transparent,
                    shape: new RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(0.0),
                            topLeft: Radius.circular(0.0))),
                    onPressed: () {
                      Navigator.pop(context);
                      isVideo = false;
                      _getImage();
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
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  minWidth: screenSize.width,
                  height: 45.0,
                  child: FlatButton(
                    //splashColor: Colors.transparent,
                    //highlightColor: Colors.transparent,
                    child: Text(
                      AppLocalizations.instance.text('video'),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.3,
                          fontFamily: 'SFProDisplayMedium'),
                    ),
                    color: Colors.transparent,
                    shape: new RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(0.0),
                            topLeft: Radius.circular(0.0))),
                    onPressed: () {
                      Navigator.pop(context);
                      isVideo = true;
                      _getVideo();
                    },
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  Future _getImage() async {
    final screenSize = MediaQuery.of(context).size;
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
              child: Text(
                AppLocalizations.instance.text('storyimg'),
                style: TextStyle(
                  fontFamily: 'SFProDisplayBold',
                  fontSize: 20.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.instance.text('descimgstory'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontFamily: 'SFProDisplayMedium',
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 30),
                  const Divider(
                    color: Color.fromRGBO(224, 224, 224, 1),
                    height: 1,
                    thickness: 0,
                    indent: 0,
                    endIndent: 0,
                  ),
                  ButtonTheme(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    minWidth: screenSize.width - 45.8,
                    height: 45.0,
                    child: FlatButton(
                      //splashColor: Colors.transparent,
                      //highlightColor: Colors.transparent,
                      child: Text(
                        AppLocalizations.instance.text('gallery'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayMedium'),
                      ),
                      color: Colors.transparent,
                      shape: new RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0.0),
                              topLeft: Radius.circular(0.0))),
                      onPressed: () async {
                        PickedFile pickedFile = await ImagePicker().getImage(
                          source: ImageSource.gallery,
                          maxWidth: 1000,
                          maxHeight: 1920,
                        );

                        _cropImage(pickedFile.path);
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
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    minWidth: screenSize.width - 45.8,
                    height: 45.0,
                    child: FlatButton(
                      //splashColor: Colors.transparent,
                      //highlightColor: Colors.transparent,
                      child: Text(
                        AppLocalizations.instance.text('camera'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayMedium'),
                      ),
                      color: Colors.transparent,
                      shape: new RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0.0),
                              topLeft: Radius.circular(0.0))),
                      onPressed: () async {
                        PickedFile pickedFile = await ImagePicker().getImage(
                          source: ImageSource.camera,
                          maxWidth: 1800,
                          maxHeight: 1800,
                        );
                        _cropImage(pickedFile.path);
                      },
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          );
        },
      );
    } catch (error) {}
  }

  Future _getVideo() async {
    final screenSize = MediaQuery.of(context).size;
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
              child: Text(
                AppLocalizations.instance.text('videostory'),
                style: TextStyle(
                  fontFamily: 'SFProDisplayBold',
                  fontSize: 20.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.instance.text('descimgstoryvideo'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontFamily: 'SFProDisplayMedium',
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 30),
                  const Divider(
                    color: Color.fromRGBO(224, 224, 224, 1),
                    height: 1,
                    thickness: 0,
                    indent: 0,
                    endIndent: 0,
                  ),
                  ButtonTheme(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    minWidth: screenSize.width - 45.8,
                    height: 45.0,
                    child: FlatButton(
                      //splashColor: Colors.transparent,
                      //highlightColor: Colors.transparent,
                      child: Text(
                        AppLocalizations.instance.text('gallery'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayMedium'),
                      ),
                      color: Colors.transparent,
                      shape: new RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0.0),
                              topLeft: Radius.circular(0.0))),
                      onPressed: () async {
                        Future<File> video1 =
                            ImagePicker.pickVideo(source: ImageSource.gallery);

                        video1.then((file) async {
                          setState(() {
                            _media = file;
                            _controller = VideoPlayerController.file(_media)
                              ..initialize().then(
                                (_) {
                                  setState(() {});
                                  _duration = _controller.value.duration;
                                  sendUploadFile();
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
                                            .text('storyupload'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      duration: Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                          });
                          Navigator.pop(context);
                        });
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
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    minWidth: screenSize.width - 45.8,
                    height: 45.0,
                    child: FlatButton(
                      //splashColor: Colors.transparent,
                      //highlightColor: Colors.transparent,
                      child: Text(
                        AppLocalizations.instance.text('camera'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayMedium'),
                      ),
                      color: Colors.transparent,
                      shape: new RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0.0),
                              topLeft: Radius.circular(0.0))),
                      onPressed: () async {
                        Future<File> video2 = ImagePicker.pickVideo(
                            source: ImageSource.camera,
                            maxDuration: Duration(seconds: 30));

                        video2.then((file) async {
                          setState(() {
                            _media = file;
                            _controller = VideoPlayerController.file(_media)
                              ..initialize().then(
                                (_) {
                                  setState(() {});
                                  _duration = _controller.value.duration;
                                  sendUploadFile();
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
                                            .text('storyupload'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      duration: Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              );
                          });
                          Navigator.pop(context);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          );
        },
      );
    } catch (error) {}
  }

  void _scrollListeners() {
    double newElevation = _controllers.offset > 0.6 ? targetElevation : 0;
    if (_elevation != newElevation) {
      setState(() {
        _elevation = newElevation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(48.0), // here the desired height
            child: Container(
              child: AppBar(
                centerTitle: false,
                automaticallyImplyLeading: false,
                actions: [
                  Container(
                      padding: const EdgeInsets.only(
                        top: 0.0,
                        bottom: 6.3,
                        left: 0,
                        right: 0,
                      ),
                      child: Row(children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            checkMediaType();
                          },
                          child: Icon(Feather.plus_circle, size: 28),
                        ),
                        SizedBox(width: 18.6),
                        IconButton(
                          icon: Icon(Feather.message_circle, size: 29),
                          padding: EdgeInsets.only(right: 20.0),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConversationListForm(0),
                              ),
                            );
                          },
                        ),
                      ])),
                ],
                title: Container(
                    padding: const EdgeInsets.only(
                      top: 0.0,
                      bottom: 8.3,
                      left: 0,
                      right: 0,
                    ),
                    child: Text(
                      'teling',
                      style: TextStyle(
                        fontFamily: "SFProDisplayBold",
                        fontSize: 33.0,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                elevation: _elevation,
              ),
            ),
          ),
          body: buildList(),
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

  swipeDownRefresh() {
    Vibrate.feedback(FeedbackType.medium);
  }

  Widget buildList() {
    final screenSize = MediaQuery.of(context).size;
    String mlangCode = AppLocalizations.instance.mlangCode;
    // print("mlangCode = $mlangCode");

    return FutureBuilder<NewsFeedState>(
        future: _buildList,
        builder: (context, snapshot) {
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
                      controller: _controllers,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data.data.length == null
                          ? 1
                          : snapshot.data.data.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Column(children: [
                            Column(children: [
                              SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    showMaterialModalBottomSheet(
                                        backgroundColor: Colors.white,
                                        elevation: 0.90,
                                        isDismissible: true,
                                        barrierColor:
                                            Colors.black.withOpacity(0.20),
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
                                    margin: const EdgeInsets.only(
                                        left: 13.0, right: 13.0),
                                    padding: const EdgeInsets.only(
                                        top: 9, bottom: 0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        width: 0.8,
                                        color:
                                            Color.fromRGBO(207, 207, 207, 0.80),
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              15.0) //         <--- border radius here
                                          ),
                                    ),
                                    child: Column(children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
                                        child: Row(children: <Widget>[
                                          Container(
                                            width: 45,
                                            height: 45,
                                            child: global.avatar == null
                                                ? SizedBox(
                                                    height: 45.0,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(100.0),
                                                      child: Shimmer(
                                                        duration: Duration(
                                                            seconds:
                                                                1), //Default value
                                                        interval: Duration(
                                                            seconds:
                                                                1), //Default value: Duration(seconds: 0)
                                                        color: Colors
                                                            .black, //Default value
                                                        enabled:
                                                            true, //Default value
                                                        direction: ShimmerDirection
                                                            .fromLTRB(), //Default Value
                                                        child: Container(
                                                          width: 110,
                                                          height: 190,
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black12,
                                                            borderRadius:
                                                                new BorderRadius
                                                                        .circular(
                                                                    100),
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
                                          SizedBox(width: 15),
                                          Expanded(
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 0,
                                                    ),
                                                    child: Text(
                                                     AppLocalizations.instance
                                                          .text('tabupload'),
                                                      style: TextStyle(
                                                        color: Color.fromRGBO(
                                                            79, 79, 79, 1),
                                                        fontFamily:
                                                            "SFProDisplayMedium",
                                                        fontSize: 15.0,
                                                        // fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ]),
                                          )
                                        ]),
                                      ),
                                      SizedBox(height: 8),
                                      Divider(
                                        color: Color.fromRGBO(207, 207, 207, 1),
                                        height: 1,
                                        thickness: 0,
                                        indent: 0,
                                        endIndent: 0,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15),
                                          ),
                                        ),
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          bottom: 8,
                                        ),
                                        child: Center(
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Color.fromRGBO(
                                                              207,
                                                              207,
                                                              207,
                                                              0.90),
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                    ),
                                                    height: 30,
                                                    child: FlatButton(
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(Feather.radio,
                                                                color:
                                                                    Colors.red,
                                                                size: 20),
                                                            SizedBox(
                                                              width: 5.0,
                                                            ),
                                                            Text(
                                                              'Live',
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "SFProDisplayMedium",
                                                                fontSize: 14.5,
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
                                                        Navigator.push(
                                                            context,
                                                            trans.PageTransition(
                                                                type: trans
                                                                    .PageTransitionType
                                                                    .rippleLeftUp,
                                                                child:
                                                                    LivePage()));
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Color.fromRGBO(
                                                              207,
                                                              207,
                                                              207,
                                                              0.90),
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                    ),
                                                    height: 30,
                                                    child: FlatButton(
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(Feather.camera,
                                                                color: Colors
                                                                    .green,
                                                                size: 20),
                                                            SizedBox(
                                                              width: 5.0,
                                                            ),
                                                            Text(
                                                              AppLocalizations
                                                                  .instance
                                                                  .text(
                                                                      'photo'),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "SFProDisplayMedium",
                                                                fontSize: 14.5,
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
                                                        showMaterialModalBottomSheet(
                                                            backgroundColor:
                                                                Colors.white,
                                                            elevation: 0.90,
                                                            isDismissible: true,
                                                            barrierColor: Colors
                                                                .black
                                                                .withOpacity(
                                                                    0.20),
                                                            enableDrag: true,
                                                            expand: false,
                                                            context: context,
                                                            builder: (context) =>
                                                                ConstrainedBox(
                                                                  constraints:
                                                                      new BoxConstraints(
                                                                          //  minHeight: screenSize.height - 120,
                                                                          //  maxHeight: screenSize.height - 120,
                                                                          ),
                                                                  child:
                                                                      TabPhoto(),
                                                                ));
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    height: 30,
                                                    child: FlatButton(
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Icon(Feather.video,
                                                                color: Colors
                                                                    .deepPurpleAccent,
                                                                size: 20),
                                                            SizedBox(
                                                              width: 5.0,
                                                            ),
                                                            Text(
                                                              'Video',
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    "SFProDisplayMedium",
                                                                fontSize: 14.5,
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
                                                        showMaterialModalBottomSheet(
                                                            backgroundColor:
                                                                Colors.white,
                                                            elevation: 0.90,
                                                            isDismissible: true,
                                                            barrierColor: Colors
                                                                .black
                                                                .withOpacity(
                                                                    0.20),
                                                            enableDrag: true,
                                                            expand: false,
                                                            context: context,
                                                            builder: (context) =>
                                                                ConstrainedBox(
                                                                  constraints:
                                                                      new BoxConstraints(
                                                                          //  minHeight: screenSize.height - 120,
                                                                          //  maxHeight: screenSize.height - 120,
                                                                          ),
                                                                  child:
                                                                      TabVideo(),
                                                                ));
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                              
                              SizedBox(
                                height: 8,
                              ),
                              
                              Container(
                                padding: const EdgeInsets.only(
                                  top: 0.0,
                                  bottom: 8.8,
                                  left: 0,
                                  right: 0,
                                ),
                                child: StreamBuilder(
                                  stream: bloc.allStories,
                                  builder: (
                                    context,
                                    AsyncSnapshot<UserModel> snapshot,
                                  ) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data.datas.length == 0) {
                                        return Center();
                                      } else {
                                        return SizedBox(
                                          height: 180.0,
                                          child: ListView.builder(
                                            addAutomaticKeepAlives: true,
                                            padding: const EdgeInsets.only(
                                              top: 0.0,
                                              bottom: 0.0,
                                              left: 8,
                                              right: 8,
                                            ),
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                snapshot.data.datas.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return (isBlock(snapshot
                                                              .data
                                                              .datas[index]
                                                              .id) ==
                                                          true) ||
                                                      (isBlocked(snapshot
                                                              .data
                                                              .datas[index]
                                                              .block) ==
                                                          true)
                                                  ? Container()
                                                  : Row(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 5,
                                                                  left: 5),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                  context,
                                                                  PageTransition(
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            1),
                                                                    type: PageTransitionType
                                                                        .fade,
                                                                    child:
                                                                        Stories(
                                                                      snapshot
                                                                          .data
                                                                          .datas[
                                                                              index]
                                                                          .id,
                                                                      snapshot
                                                                          .data
                                                                          .datas[
                                                                              index]
                                                                          .name,
                                                                      snapshot
                                                                          .data
                                                                          .datas[
                                                                              index]
                                                                          .avatar,
                                                                      snapshot
                                                                          .data
                                                                          .datas[
                                                                              index]
                                                                          .badge,
                                                                    ),
                                                                  ));
                                                            },
                                                            child: Stack(
                                                                children: <
                                                                    Widget>[
                                                                  ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15.0),
                                                                      child: Stack(
                                                                          children: <
                                                                              Widget>[
                                                                            Container(
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.black,
                                                                                borderRadius: BorderRadius.circular(15),
                                                                              ),
                                                                              width: 105,
                                                                              height: 165,
                                                                              child: ShaderMask(
                                                                                shaderCallback: (rect) {
                                                                                  return LinearGradient(
                                                                                    begin: Alignment.topCenter,
                                                                                    end: Alignment.bottomCenter,
                                                                                    colors: <Color>[
                                                                                      Colors.black.withOpacity(1.0),
                                                                                      Colors.black.withOpacity(1.0),
                                                                                      Colors.black.withOpacity(0.1),
                                                                                      Colors.black.withOpacity(0.1),
                                                                                    ],
                                                                                    stops: [
                                                                                      0.50,
                                                                                      0.50,
                                                                                      1.0,
                                                                                      0.5
                                                                                    ],
                                                                                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                                                                                },
                                                                                blendMode: BlendMode.dstIn,
                                                                                child: StoriesPreview(
                                                                                  snapshot.data.datas[index].id,
                                                                                  snapshot.data.datas[index].name,
                                                                                  snapshot.data.datas[index].avatar,
                                                                                  snapshot.data.datas[index].badge,
                                                                                ),
                                                                              ),
                                                                            ),

                                                                            //    Container(
                                                                            //     decoration: BoxDecoration(
                                                                            //        borderRadius: BorderRadius.circular(15),
                                                                            //      ),
                                                                            //      width: 110,
                                                                            //      height: 140,
                                                                            //      child: BackdropFilter(
                                                                            //         filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7,),

                                                                            //        child: Container(
                                                                            //          decoration: BoxDecoration(
                                                                            //            color: Colors.black.withOpacity(0.13),
                                                                            //            borderRadius: BorderRadius.circular(15),
                                                                            //           ),
                                                                            //           child: Container(
                                                                            //           decoration: BoxDecoration(
                                                                            //             color: Colors.black.withOpacity(0.13),
                                                                            //             borderRadius: BorderRadius.circular(15),
                                                                            //           ),
                                                                            //         ),
                                                                            //          ),
                                                                            //        ),
                                                                            //      ),
                                                                            //    ])),

                                                                            Positioned(
                                                                              top: 5.0,
                                                                              left: 5.0,
                                                                              right: 68.0,
                                                                              child: Container(
                                                                                decoration: BoxDecoration(
                                                                                  boxShadow: [
                                                                                    BoxShadow(
                                                                                      color: Colors.black.withOpacity(0.20),
                                                                                      spreadRadius: 2,
                                                                                      blurRadius: 4,
                                                                                      offset: Offset(0, 0), // changes position of shadow
                                                                                    ),
                                                                                  ],
                                                                                  borderRadius: BorderRadius.circular(100.0),
                                                                                  border: Border.all(
                                                                                    width: 2,
                                                                                    color: Colors.white,
                                                                                  ),
                                                                                ),
                                                                                child: ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(100.0),
                                                                                  child: CachedNetworkImage(
                                                                                    fit: BoxFit.cover,
                                                                                    placeholder: (c, d) {
                                                                                      return Center();
                                                                                    },
                                                                                    imageUrl: snapshot.data.datas[index].avatar,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ])),
                                                                  Positioned(
                                                                    bottom:
                                                                        11.0,
                                                                    left: 5.0,
                                                                    right: 5.0,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(top: 4.0),
                                                                          child:
                                                                              SizedBox(
                                                                            child:
                                                                                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                                                                              Text(
                                                                                snapshot.data.datas[index].name,
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontFamily: "SFProDisplaySemiBold",
                                                                                  fontSize: 11,
                                                                                  shadows: <Shadow>[
                                                                                    Shadow(
                                                                                      offset: Offset(0.0, 0.0),
                                                                                      blurRadius: 18.0,
                                                                                      color: Color.fromARGB(255, 0, 0, 0),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              snapshot.data.datas[index].badge == 'true'
                                                                                  ? Container(
                                                                                      decoration: BoxDecoration(
                                                                                        boxShadow: [
                                                                                          BoxShadow(
                                                                                            color: Colors.black.withOpacity(0.10),
                                                                                            spreadRadius: 5,
                                                                                            blurRadius: 10,
                                                                                            offset: Offset(0, 4),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.only(left: 3),
                                                                                        child: Icon(
                                                                                          Icons.check_circle,
                                                                                          size: 9.5,
                                                                                          color: Colors.white,
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                  : Container(),
                                                                            ]),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  )
                                                                ]),
                                                          ),
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

                                    return SizedBox(
                                      height: 195.0,
                                      child: ListView(
                                          addAutomaticKeepAlives: true,
                                          padding: const EdgeInsets.only(
                                            top: 0.0,
                                            bottom: 5.0,
                                            left: 8,
                                            right: 8,
                                          ),
                                          scrollDirection: Axis.horizontal,
                                          children: <Widget>[
                                            SizedBox(width: 8),
                                            SizedBox(
                                              height: 80.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        15.0),
                                                child: Shimmer(
                                                  duration: Duration(
                                                      seconds:
                                                          1), //Default value
                                                  interval: Duration(
                                                      seconds:
                                                          1), //Default value: Duration(seconds: 0)
                                                  color: Colors
                                                      .black, //Default value
                                                  enabled: true, //Default value
                                                  direction: ShimmerDirection
                                                      .fromLTRB(), //Default Value
                                                  child: Container(
                                                    transform: Matrix4
                                                        .translationValues(
                                                            0.0, 4.0, 0.0),
                                                    width: 105,
                                                    height: 180,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            SizedBox(
                                              height: 94.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        15.0),
                                                child: Shimmer(
                                                  duration: Duration(
                                                      seconds:
                                                          1), //Default value
                                                  interval: Duration(
                                                      seconds:
                                                          1), //Default value: Duration(seconds: 0)
                                                  color: Colors
                                                      .black, //Default value
                                                  enabled: true, //Default value
                                                  direction: ShimmerDirection
                                                      .fromLTRB(), //Default Value
                                                  child: Container(
                                                    transform: Matrix4
                                                        .translationValues(
                                                            0.0, 4.0, 0.0),
                                                    width: 105,
                                                    height: 160,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            SizedBox(
                                              height: 94.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        15.0),
                                                child: Shimmer(
                                                  duration: Duration(
                                                      seconds:
                                                          1), //Default value
                                                  interval: Duration(
                                                      seconds:
                                                          1), //Default value: Duration(seconds: 0)
                                                  color: Colors
                                                      .black, //Default value
                                                  enabled: true, //Default value
                                                  direction: ShimmerDirection
                                                      .fromLTRB(), //Default Value
                                                  child: Container(
                                                    transform: Matrix4
                                                        .translationValues(
                                                            0.0, 4.0, 0.0),
                                                    width: 105,
                                                    height: 160,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            SizedBox(
                                              height: 94.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        15.0),
                                                child: Shimmer(
                                                  duration: Duration(
                                                      seconds:
                                                          1), //Default value
                                                  interval: Duration(
                                                      seconds:
                                                          1), //Default value: Duration(seconds: 0)
                                                  color: Colors
                                                      .black, //Default value
                                                  enabled: true, //Default value
                                                  direction: ShimmerDirection
                                                      .fromLTRB(), //Default Value
                                                  child: Container(
                                                    transform: Matrix4
                                                        .translationValues(
                                                            0.0, 4.0, 0.0),
                                                    width: 105,
                                                    height: 160,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            SizedBox(
                                              height: 94.0,
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        15.0),
                                                child: Shimmer(
                                                  duration: Duration(
                                                      seconds:
                                                          1), //Default value
                                                  interval: Duration(
                                                      seconds:
                                                          1), //Default value: Duration(seconds: 0)
                                                  color: Colors
                                                      .black, //Default value
                                                  enabled: true, //Default value
                                                  direction: ShimmerDirection
                                                      .fromLTRB(), //Default Value
                                                  child: Container(
                                                    transform: Matrix4
                                                        .translationValues(
                                                            0.0, 4.0, 0.0),
                                                    width: 105,
                                                    height: 160,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black12,
                                                      borderRadius:
                                                          new BorderRadius
                                                              .circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                    );
                                  },
                                ),
                              ),
                              Column(children: <Widget>[
                                Divider(
                                  color: Color.fromRGBO(207, 207, 207, 0.90),
                                  height: 1,
                                  thickness: 0,
                                  indent: 0,
                                  endIndent: 0,
                                ),
                                Container(
                                  height: 7,
                                  color: Color.fromRGBO(207, 207, 207, 0.30),
                                ),
                                Divider(
                                  color: Color.fromRGBO(207, 207, 207, 0.90),
                                  height: 1,
                                  thickness: 0,
                                  indent: 0,
                                  endIndent: 0,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Covid19()));
                                  },
                                  child: Container(
                                    height: 40,
                                    width: screenSize.width,
                                    child: Center(
                                      child: Container(
                                        transform: Matrix4.translationValues(
                                            -2.0, 0.0, 0.0),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(Feather.alert_circle,
                                                  size: 18, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.instance
                                                    .text('covidtitle2'),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily:
                                                      'SFProDisplaySemiBold',
                                                  fontSize: 12.5,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ]),
                                      ),
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: Color.fromRGBO(207, 207, 207, 0.90),
                                  height: 1,
                                  thickness: 0,
                                  indent: 0,
                                  endIndent: 0,
                                ),
                                Container(
                                  height: 7,
                                  color: Color.fromRGBO(207, 207, 207, 0.30),
                                ),
                                Divider(
                                  color: Color.fromRGBO(207, 207, 207, 0.90),
                                  height: 1,
                                  thickness: 0,
                                  indent: 0,
                                  endIndent: 0,
                                ),
                              ]),
                            ]),
                          ]);
                        }
                        index -= 1;
                        return (isBlock(snapshot
                                        .data.data[index].user.data.id) ==
                                    true) ||
                                (isBlocked(snapshot
                                        .data.data[index].user.data.block) ==
                                    true)
                            ? Container()
                            : Column(
                                children: <Widget>[
                                  new Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                            .data[index]
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
                                                      new BorderRadius.circular(
                                                          30.0),
                                                  child: CachedNetworkImage(
                                                    height:
                                                        kToolbarHeight / 1.35,
                                                    width:
                                                        kToolbarHeight / 1.35,
                                                    fit: BoxFit.cover,
                                                    placeholder: (c, d) {
                                                      return Center(
                                                        child: SizedBox(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.35,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.35,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                new BorderRadius
                                                                        .circular(
                                                                    100.0),
                                                            child: Shimmer(
                                                              duration: Duration(
                                                                  seconds:
                                                                      1), //Default value
                                                              interval: Duration(
                                                                  seconds:
                                                                      1), //Default value: Duration(seconds: 0)
                                                              color: Colors
                                                                  .black, //Default value
                                                              enabled:
                                                                  true, //Default value
                                                              direction:
                                                                  ShimmerDirection
                                                                      .fromLTRB(), //Default Value
                                                              child: Container(
                                                                width: 110,
                                                                height: 190,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black12,
                                                                  borderRadius:
                                                                      new BorderRadius
                                                                              .circular(
                                                                          100),
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
                                                      children: <Widget>[
                                                        Row(children: [
                                                          new Text(
                                                            snapshot
                                                                .data
                                                                .data[index]
                                                                .user
                                                                .data
                                                                .name,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  "SFProDisplayBold",
                                                              fontSize: 15.5,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 4,
                                                          ),
                                                          snapshot
                                                                      .data
                                                                      .data[
                                                                          index]
                                                                      .user
                                                                      .data
                                                                      .badge ==
                                                                  'true'
                                                              ? Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .only(
                                                                              top: 1.5),
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .transparent),
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(0),
                                                                    child: Icon(
                                                                        Icons
                                                                            .check_circle,
                                                                        size:
                                                                            13.5,
                                                                        color: Colors
                                                                            .blue),
                                                                  ),
                                                                )
                                                              : Container(),
                                                        ]),
                                                        SizedBox(
                                                          height: 2.0,
                                                        ),
                                                        new Text(
                                                          timeago.format(
                                                              DateTime.parse(snapshot
                                                                      .data
                                                                      .data[
                                                                          index]
                                                                      .createdat)
                                                                  .toLocal(),
                                                              locale:
                                                                  AppLocalizations
                                                                      .instance
                                                                      .mlangCode),
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "SFProDisplayRegular",
                                                            fontSize: 13.5,
                                                            color:
                                                                Color.fromRGBO(
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
                                          child:
                                              const Icon(LineIcons.ellipsis_h),
                                          onPressed: () {
                                            showModalBottomSheet<dynamic>(
                                              backgroundColor:
                                                  Colors.transparent,
                                              isScrollControlled: true,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0)),
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Wrap(children: <Widget>[
                                                  Container(
                                                    decoration:
                                                        new BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30.0),
                                                    ),
                                                    child: Container(
                                                      child: Column(
                                                        children: <Widget>[
                                                          new Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                    width: screenSize
                                                                            .width -
                                                                        45,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                    child: Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          ButtonTheme(
                                                                            minWidth:
                                                                                screenSize.width - 45.8,
                                                                            height:
                                                                                56.0,
                                                                            child:
                                                                                FlatButton(
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
                                                                            color: Color.fromRGBO(
                                                                                224,
                                                                                224,
                                                                                224,
                                                                                1),
                                                                            height:
                                                                                1,
                                                                            thickness:
                                                                                0,
                                                                            indent:
                                                                                0,
                                                                            endIndent:
                                                                                0,
                                                                          ),
                                                                          ButtonTheme(
                                                                            minWidth:
                                                                                screenSize.width - 45.8,
                                                                            height:
                                                                                56.0,
                                                                            child:
                                                                                FlatButton(
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
                                                                            color: Color.fromRGBO(
                                                                                224,
                                                                                224,
                                                                                224,
                                                                                1),
                                                                            height:
                                                                                1,
                                                                            thickness:
                                                                                0,
                                                                            indent:
                                                                                0,
                                                                            endIndent:
                                                                                0,
                                                                          ),
                                                                          ButtonTheme(
                                                                            minWidth:
                                                                                screenSize.width - 45.8,
                                                                            height:
                                                                                56.0,
                                                                            child:
                                                                                FlatButton(
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
                                                          Container(height: 10),
                                                          ButtonTheme(
                                                            minWidth: screenSize
                                                                    .width -
                                                                45.8,
                                                            height: 56.0,
                                                            child: FlatButton(
                                                                child: Text(
                                                                  AppLocalizations
                                                                      .instance
                                                                      .text(
                                                                          'cancel'),
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          16.3,
                                                                      fontFamily:
                                                                          'SFProDisplayMedium'),
                                                                ),
                                                                color: Colors
                                                                    .white,
                                                                shape: new RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        new BorderRadius.circular(
                                                                            10.0)),
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                }),
                                                          ),
                                                          Container(height: 40),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                ]);
                                              },
                                            );
                                          },
                                        ),
                                      ]),
                                  GestureDetector(
                                      onDoubleTap: () {
                                        (snapshot.data.data[index].like ==
                                                "true")
                                            ? bloc.unlikepost(
                                                snapshot.data.data[index].id)
                                            : bloc.likepost(
                                                snapshot.data.data[index].id);
                                        _fservice.saveUserPostLikeFirestore(
                                            snapshot.data.data[index].userid);
                                        Vibrate.feedback(FeedbackType.medium);

                                        likeShow();
                                      },
                                      child: Stack(children: <Widget>[
                                        Container(
                                          child: Stack(children: <Widget>[
                                            new Container(
                                              padding: EdgeInsets.only(
                                                left: 0,
                                                right: 0,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    new BorderRadius.circular(
                                                        0.0),
                                                child: checkFileType(snapshot
                                                            .data
                                                            .data[index]
                                                            .image) ==
                                                        "image"
                                                    ? PinchZoomImage(
                                                        hideStatusBarWhileZooming:
                                                            true,
                                                        image:
                                                            CachedNetworkImage(
                                                          width:
                                                              screenSize.width,
                                                          placeholder: (c, d) {
                                                            return Container(
                                                              height: 300,
                                                              width: screenSize
                                                                  .width,
                                                            );
                                                          },
                                                          fit: BoxFit.cover,
                                                          imageUrl: snapshot
                                                              .data
                                                              .data[index]
                                                              .image,
                                                        ),
                                                        zoomedBackgroundColor:
                                                            Color.fromRGBO(240,
                                                                240, 240, 0.50),
                                                      )
                                                    : Container(
                                                        width: screenSize.width,
                                                        child: VideoClip(
                                                          url: snapshot
                                                              .data
                                                              .data[index]
                                                              .image,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ])),
                                  SizedBox(
                                    height: 0.0,
                                  ),
                                  Container(
                                    width: screenSize.width,
                                    child: new Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: screenSize.width,
                                            child: Container(
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(
                                                left: 16.0,
                                                top: 13,
                                                bottom: 13,
                                                right: 16.0,
                                              ),
                                              child: new Column(
                                                children: <Widget>[
                                                  RichText(
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                        color: Color.fromRGBO(
                                                            28, 28, 28, 1),
                                                      ),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: snapshot
                                                              .data
                                                              .data[index]
                                                              .description,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "SFProDisplayMedium",
                                                            fontSize: 13.7,
                                                            color:
                                                                Color.fromRGBO(
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
                                  ),
                                  Column(children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.only(bottom: 0.0),
                                      child: const Divider(
                                        color: Color.fromRGBO(207, 207, 207, 1),
                                        height: 1,
                                        thickness: 0,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                    ),
                                    Center(
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            Expanded(
                                              child: Container(
                                                height: 42,
                                                child: FlatButton(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                        (snapshot
                                                                    .data
                                                                    .data[index]
                                                                    .like ==
                                                                "true")
                                                            ? Icon(
                                                                Icons.favorite,
                                                                color:
                                                                    Colors.red,
                                                                size: 23)
                                                            : Icon(
                                                                Icons
                                                                    .favorite_border,
                                                                size: 23,
                                                                color: Color
                                                                    .fromRGBO(
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
                                                                  .data[index]
                                                                  .likecount
                                                                  .toString() +
                                                              ' ' +
                                                              AppLocalizations
                                                                  .instance
                                                                  .text('like'),
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "SFProDisplayMedium",
                                                            fontSize: 14.5,
                                                            color:
                                                                Color.fromRGBO(
                                                                    79,
                                                                    79,
                                                                    79,
                                                                    1),
                                                          ),
                                                        ),
                                                      ]),
                                                  onPressed: () {
                                                    Vibrate.feedback(
                                                        FeedbackType.medium);
                                                    likeShow();
                                                    (snapshot.data.data[index]
                                                                .like ==
                                                            "true")
                                                        ? bloc.unlikepost(
                                                            snapshot.data
                                                                .data[index].id)
                                                        : bloc.likepost(snapshot
                                                            .data
                                                            .data[index]
                                                            .id);
                                                    _fservice
                                                        .saveUserPostLikeFirestore(
                                                            snapshot
                                                                .data
                                                                .data[index]
                                                                .userid);
                                                    flareControls.play("like");
                                                    Vibrate.feedback(
                                                        FeedbackType.medium);
                                                  },
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 42,
                                              child: FlatButton(
                                                splashColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Transform(
                                                        alignment:
                                                            Alignment.center,
                                                        transform:
                                                            Matrix4.rotationY(
                                                                math.pi),
                                                        child: Icon(
                                                            ico.Feather
                                                                .message_circle,
                                                            color:
                                                                Color.fromRGBO(
                                                                    79,
                                                                    79,
                                                                    79,
                                                                    1),
                                                            size: 21.7),
                                                      ),
                                                      SizedBox(
                                                        width: 5.0,
                                                      ),
                                                      Center(
                                                        child: Text(
                                                          snapshot
                                                                  .data
                                                                  .data[index]
                                                                  .commentcount
                                                                  .toString() +
                                                              ' ' +
                                                              AppLocalizations
                                                                  .instance
                                                                  .text(
                                                                      'comments'),
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "SFProDisplayMedium",
                                                            fontSize: 14.5,
                                                            color:
                                                                Color.fromRGBO(
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
                                                          Colors.white,
                                                      elevation: 0.90,
                                                      isDismissible: true,
                                                      barrierColor: Colors.black
                                                          .withOpacity(0.20),
                                                      enableDrag: true,
                                                      expand: false,
                                                      context: context,
                                                      builder: (context) =>
                                                          ConstrainedBox(
                                                            constraints:
                                                                new BoxConstraints(
                                                              minHeight: screenSize
                                                                      .height -
                                                                  120,
                                                              maxHeight: screenSize
                                                                      .height -
                                                                  120,
                                                            ),
                                                            child: Comments(
                                                                snapshot
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
                                                splashColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      snapshot.data.data[index]
                                                                  .saved !=
                                                              "true"
                                                          ? Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                  Icon(
                                                                      Icons
                                                                          .bookmark_border,
                                                                      color: Color
                                                                          .fromRGBO(
                                                                              79,
                                                                              79,
                                                                              79,
                                                                              1),
                                                                      size:
                                                                          22.6),
                                                                  SizedBox(
                                                                    width: 5.0,
                                                                  ),
                                                                  Text(
                                                                    AppLocalizations
                                                                        .instance
                                                                        .text(
                                                                            'save'),
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
                                                                ])
                                                          : Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                  Icon(
                                                                      Icons
                                                                          .bookmark,
                                                                      color: Color
                                                                          .fromRGBO(
                                                                              78,
                                                                              187,
                                                                              31,
                                                                              1),
                                                                      size:
                                                                          22.6),
                                                                  SizedBox(
                                                                    width: 5.0,
                                                                  ),
                                                                  Text(
                                                                    AppLocalizations
                                                                        .instance
                                                                        .text(
                                                                            'savedposticon'),
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
                                                    ]),
                                                onPressed: () {
                                                  Vibrate.feedback(
                                                      FeedbackType.medium);
                                                  (snapshot.data.data[index]
                                                              .saved ==
                                                          "true")
                                                      ? bloc.removePost(snapshot
                                                              .data
                                                              .data[index]
                                                              .id) +
                                                          Scaffold.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom: 5,
                                                                      top: 5),
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          13,
                                                                      left: 13,
                                                                      right:
                                                                          13),
                                                              elevation: 0,
                                                              backgroundColor:
                                                                  Color
                                                                      .fromRGBO(
                                                                          78,
                                                                          187,
                                                                          31,
                                                                          1),
                                                              content: Text(
                                                                AppLocalizations
                                                                    .instance
                                                                    .text(
                                                                        'removesaved'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      1300),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          )
                                                      : bloc.savePost(snapshot
                                                              .data
                                                              .data[index]
                                                              .id) +
                                                          Scaffold.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      bottom: 5,
                                                                      top: 5),
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      bottom:
                                                                          13,
                                                                      left: 13,
                                                                      right:
                                                                          13),
                                                              elevation: 0,
                                                              backgroundColor:
                                                                  Color
                                                                      .fromRGBO(
                                                                          78,
                                                                          187,
                                                                          31,
                                                                          1),
                                                              content: Text(
                                                                AppLocalizations
                                                                    .instance
                                                                    .text(
                                                                        'postaddsave'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      1300),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                },
                                              ),
                                            )),
                                          ]),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.only(bottom: 5.0),
                                      child: const Divider(
                                        color: Color.fromRGBO(207, 207, 207, 1),
                                        height: 1,
                                        thickness: 0,
                                        indent: 0,
                                        endIndent: 0,
                                      ),
                                    ),
                                  ])
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
        });
  }
}

Widget buildProfileImgHeader(context, AsyncSnapshot<UserModel> user) {
  return Container(
    color: Colors.black,
    width: double.infinity,
    height: 313,
    child: user.data.user.cover != null
        ? CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: user.data.user.cover,
          )
        : Container(
            height: kToolbarHeight * 3,
            width: kToolbarHeight * 3,
            child: Container(
                transform: Matrix4.translationValues(0.0, -12.0, 0.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.instance.text('photocover'),
                        style: new TextStyle(
                          fontFamily: 'SFProDisplayMedium',
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppLocalizations.instance.text('photocover2'),
                        style: new TextStyle(
                          fontFamily: 'SFProDisplayMedium',
                          fontSize: 16,
                        ),
                      )
                    ]))),
  );
}

String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return NetworkUtils.BannerAdUnitIdAndroid;
  } else if (Platform.isAndroid) {
    return NetworkUtils.BannerAdUnitIdIOS;
  }
  return null;
}
