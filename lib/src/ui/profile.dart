import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:Storyteller/app_localizations.dart';
import 'package:Storyteller/src/constant/httpService.dart';
import 'package:Storyteller/src/constant/utils.dart';
import 'package:Storyteller/src/ui/blocked%20users.dart';
import 'package:Storyteller/src/ui/conversation_list.dart';
import 'package:Storyteller/src/ui/edit_profile.dart';
import 'package:Storyteller/src/ui/profile_post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:Storyteller/src/ui/edit_cover.dart';
import 'package:Storyteller/src/ui/saved_posts.dart';
import 'package:Storyteller/src/ui/video_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Storyteller/src/models/user_model.dart';
import 'package:Storyteller/src/ui/conversation_send.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'bottomNavigation.dart';
import 'settings.dart';
import 'package:line_icons/line_icons.dart';
import '../blocs/profile_bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:async';
import 'package:mime/mime.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:open_app_settings/open_app_settings.dart';
import 'package:async/async.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:Storyteller/src/resources/firebase_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'globals.dart' as global;

class StorytellerProfile extends StatefulWidget {
  final int idController;
  final bool searchContentPage;
  final Function() notifyParent;

  StorytellerProfile(
      this.idController, this.searchContentPage, this.notifyParent,
      {Key key})
      : super(key: key);

  @override
  MyTimelinePage createState() => new MyTimelinePage();
}

class MyTimelinePage extends State<StorytellerProfile>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  bool lastStatus = true;
  Timer _timer;
  File _media;
  bool isVideo = false;

  VideoPlayerController _controller;
  Duration _duration;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  int counterbus = 0;
  Color _colorforFollow = Color.fromRGBO(0, 141, 252, 1);
  Color _colorforUnfollow = Color.fromRGBO(212, 212, 212, 1);
  Color blue = Color.fromRGBO(0, 0, 0, 1);
  int likebus = 0;
  FirebaseService _fservice = new FirebaseService();

  TabController controller;

  _scrollListener() {
    if (isShrink != lastStatus) {
      setState(() {
        lastStatus = isShrink;
      });
    }
  }

  checkFileType(String url) {
    String mimeStr = lookupMimeType(url);
    var fileType = mimeStr.split('/');
    print(fileType[0]);
    return fileType[0];
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

  void _onRefresh() async {
    Vibrate.feedback(FeedbackType.medium);
    // monitor network fetch
    // await bloc.fetchUser();
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }

  bool auto = false;

  bool isBlock(int id) {
    var blocklist = global.blockList.split(",");
    return blocklist.contains(id.toString());
  }

  bool isBlocked(String list) {
    var id = global.userId;
    var blocklist = list.split(",");
    return blocklist.contains(id.toString());
  }

  bool get isShrink {
    return _scrollController.hasClients &&
        _scrollController.offset > (245 - kToolbarHeight);
  }

  @override
  void initState() {
    controller = new TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();

    if (widget.idController != 0) {
      auto = true;
    }
    check().then(
      (internet) {
        if (internet == false) {
        } else {
          print(global.userId);
          if (widget.searchContentPage == true) {
            global.spin = true;
          } else {
            global.spin = false;
          }
          bloc.fetchUser(widget.idController);
          bloc.fetchUserPhotos(widget.idController);
          bloc.photoFetcherStatus.listen((onData) {
            if (likebus <= 0) {
              setState(() {
                likebus++;
              });
            }

            bloc.fetchUserPhotos(widget.idController);
          });
          bloc.userFetcherStatus.listen(
            (onData) {
              if (counterbus <= 0) {
                if (!mounted) return;
                setState(() {
                  counterbus++;
                });

                bloc.fetchUser(widget.idController);
              }
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    bloc.dispose();
    super.dispose();
  }

  void savedShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: new Text(
            AppLocalizations.instance.text('successreport'),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Container(
            padding: EdgeInsets.only(top: 40.0),
            child: Icon(
              Icons.check_circle,
              size: 50,
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

  void blockuser(int block_id) {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Container(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              SizedBox(height: 5),
              Icon(Feather.alert_triangle, size: 55),
              SizedBox(height: 20),
              new Text(
                AppLocalizations.instance.text('blockuser'),
                textAlign: TextAlign.center,
                style: new TextStyle(
                  fontSize: 13.6,
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
                    AppLocalizations.instance.text(
                      'block',
                    ),
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
                    bloc.blockuser(block_id);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryTellerBottom(),
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
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                minWidth: screenSize.width,
                height: 45.0,
                child: FlatButton(
                  //splashColor: Colors.transparent,
                  //highlightColor: Colors.transparent,
                  child: Text(
                    AppLocalizations.instance.text(
                      'cancel',
                    ),
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
            ]),
          ),
        );
      },
    );
  }

  Future<String> fetchToken() async {
    var client = await HttpService().getClient();
    return client.credentials.accessToken.toString();
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

  swipeDownRefresh() {}
  refresh() {}

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    );
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                brightness: isShrink ? Brightness.light : Brightness.dark,
                elevation: 0.6,
                expandedHeight: 313,
                pinned: true,
                backgroundColor: Colors.white,
                floating: false,
                automaticallyImplyLeading: false,
                centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: StreamBuilder(
                    stream: bloc.userDetail,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                            margin: EdgeInsets.only(left: 10),
                            child: buildProfileTitle(
                                context, snapshot, widget.idController));
                      }

                      return SizedBox();
                    },
                  ),
                  background: StreamBuilder(
                    stream: bloc.userDetail,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          child: buildProfileImgHeader(
                              context, snapshot, widget.idController),
                        );
                      }

                      return SizedBox();
                    },
                  ),
                ),
                leading: auto
                    ? Container(
                        transform: Matrix4.translationValues(5.0, 0.0, 0.0),
                        padding: EdgeInsets.only(left: 10.0, bottom: 0),
                        child: BackButton(
                          color: isShrink ? Colors.black : Colors.white,
                        ),
                      )
                    : StreamBuilder(
                        stream: bloc.userDetail,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                                child: buildProfileAdd(
                                    context, snapshot, widget.idController));
                          }

                          return SizedBox();
                        },
                      ),
                actions: [
                  StreamBuilder(
                    stream: bloc.userDetail,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                            child: buildProfileSettings(
                                context, snapshot, widget.idController));
                      }

                      return SizedBox();
                    },
                  ),
                ],
              ),

              StreamBuilder(
                stream: bloc.userDetail,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                        child: buildProfileHeader(
                            context, snapshot, widget.idController));
                  }

                  return SliverToBoxAdapter(
                    child: Container(
                      height: 0.0,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                  );
                },
              ),

              StreamBuilder(
                stream: bloc.allPhotos,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.data.length == 0) {
                      return SliverToBoxAdapter(
                        child: Container(
                          height: 100.0,
                          child: Center(
                            child: Text(
                              "Sorry, but there is nothing to see.",
                              style: TextStyle(
                                fontFamily: "SFProDisplayBold",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return (isBlock(snapshot
                                            .data.data[index].user.data.id) ==
                                        true) ||
                                    (isBlocked(snapshot.data.data[index].user
                                            .data.block) ==
                                        true)
                                ? Container()
                                : Container(
                                    padding: EdgeInsets.only(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      //bottom: 15,
                                    ),
                                    transform:
                                        Matrix4.translationValues(0, 0, 0.0),
                                    child: GridView.count(
                                      addAutomaticKeepAlives: true,
                                      padding: EdgeInsets.zero,
                                      crossAxisCount: 2,
                                      childAspectRatio: 1,
                                      mainAxisSpacing: 1.8,
                                      crossAxisSpacing: 1.8,
                                      shrinkWrap: true,
                                      physics: ScrollPhysics(),
                                      children: new List.generate(
                                          snapshot.data.datas.length, (i) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        StorytellerProfilePost(
                                                          widget.idController,
                                                          false,
                                                          refresh,
                                                          i,
                                                        )));
                                          },
                                          child: checkFileType(snapshot
                                                      .data.data[i].image) ==
                                                  "image"
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          0.0),
                                                  child: CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    imageUrl: snapshot
                                                        .data.datas[i].image,
                                                  ),
                                                )
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          0.0),
                                                  child: VideoClip(
                                                      url: snapshot
                                                          .data.data[i].image),
                                                ),
                                        );
                                      }),
                                    ));
                          },
                          childCount: 1,
                        ),
                      );
                    }
                  }

                  return SliverToBoxAdapter(
                    child: Container(
                      height: 50.0,
                      child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ]),
                      ),
                    ),
                  );
                },
              ),
              //buildFullScreen()
            ],
          ),
          Container(
            height: MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
          ),
        ],
      ),
    );
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        maxWidth: 900,
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
          rectWidth: 900,
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryTellerBottom(),
        ),
      );
    }
  }

  void checkMediaType() {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Column(children: <Widget>[
              Image.network(
                'https://images.emojiterra.com/mozilla/512px/1f389.png',
                width: 80,
                height: 80,
              ),
              SizedBox(height: 15),
              Text(
                'Upload Story',
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
                  'Select the file type to upload, then you \ncan choose from the gallery or camera.',
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
                'Image Story',
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
                    'You can upload a photo or take a new one.',
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
                              topRight: Radius.circular(10.0),
                              topLeft: Radius.circular(10.0))),
                      onPressed: () async {
                        PickedFile pickedFile = await ImagePicker().getImage(
                          source: ImageSource.gallery,
                          maxWidth: 900,
                          maxHeight: 1280,
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
                              topRight: Radius.circular(10.0),
                              topLeft: Radius.circular(10.0))),
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
                'Video Story',
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
                    'You can upload a video or take a new one.',
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
                              topRight: Radius.circular(10.0),
                              topLeft: Radius.circular(10.0))),
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
                              topRight: Radius.circular(10.0),
                              topLeft: Radius.circular(10.0))),
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

  Widget buildProfileAdd(
      context, AsyncSnapshot<UserModel> user, int userowner) {
    return Container(
      child: IconButton(
        icon: Icon(
          Feather.message_circle,
          size: 28,
          color: isShrink ? Colors.black : Colors.white,
        ),
        padding: EdgeInsets.only(left: 15.0, bottom: 2),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationListForm(0),
            ),
          );
        },
      ),
    );
  }

  Widget buildProfileSettings(
      context, AsyncSnapshot<UserModel> user, int userowner) {
    return (widget.idController == 0 || widget.idController == global.userId)
        ? user.data.user.badge == 'true'
            ? Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  child: IconButton(
                      icon: Icon(
                        LineIcons.bookmark_o,
                        size: 29.5,
                        color: isShrink ? Colors.black : Colors.white,
                      ),
                      padding: EdgeInsets.only(right: 12.0, bottom: 2),
                      onPressed: () {Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SavedPosts()
                                        ),
                                      );}),
                ),
                Container(
                    child: IconButton(
                  icon: Icon(
                    LineIcons.bars,
                    size: 30.0,
                    color: isShrink ? Colors.black : Colors.white,
                  ),
                  padding: EdgeInsets.only(right: 20.0, bottom: 2),
                  onPressed: () {
                    showModalBottomSheet<dynamic>(
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      context: context,
                      builder: (BuildContext context) {
                        return Wrap(children: <Widget>[
                          Container(
                            decoration: new BoxDecoration(
                                color: Colors.white,
                                borderRadius: new BorderRadius.only(
                                    topLeft: const Radius.circular(30.0),
                                    topRight: const Radius.circular(30.0))),
                            child: Container(
                              child: Column(
                                children: <Widget>[
                                  new Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            // width: screenSize.width - 45,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.white,
                                            ),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(height: 8),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditUserForm(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.user,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'editprofile'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditCover(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.image,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text('cover'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              BlockedUsers(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.users,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'blockedusers'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      await OpenAppSettings
                                                          .openAppSettings();
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons
                                                                  .language,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(30.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'language'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SettingsForm(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.cog,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'advanceset'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                ]))
                                      ]),
                                  Container(height: 10),
                                  ButtonTheme(
                                    //minWidth:
                                    //screenSize.width -45.8,
                                    height: 56.0,
                                    child: FlatButton(
                                        // splashColor: Colors.transparent,
                                        // highlightColor: Colors.transparent,
                                        child: Text(
                                          AppLocalizations.instance
                                              .text('cancel'),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15.3,
                                              fontFamily: 'SFProDisplayMedium'),
                                        ),
                                        color: Colors.white,
                                        shape: new RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(
                                                    10.0)),
                                        onPressed: () {
                                          Navigator.pop(context);
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
                ))
              ]))
            : Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                    child: IconButton(
                  icon: Icon(
                    LineIcons.bars,
                    size: 30.0,
                    color: isShrink ? Colors.black : Colors.white,
                  ),
                  padding: EdgeInsets.only(right: 20.0, bottom: 2),
                  onPressed: () {
                    showModalBottomSheet<dynamic>(
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      context: context,
                      builder: (BuildContext context) {
                        return Wrap(children: <Widget>[
                          Container(
                            decoration: new BoxDecoration(
                                color: Colors.white,
                                borderRadius: new BorderRadius.only(
                                    topLeft: const Radius.circular(30.0),
                                    topRight: const Radius.circular(30.0))),
                            child: Container(
                              child: Column(
                                children: <Widget>[
                                  new Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            // width: screenSize.width - 45,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.white,
                                            ),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(height: 8),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditUserForm(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.user,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'editprofile'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditCover(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.image,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text('cover'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              BlockedUsers(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons
                                                                  .bookmark_o,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'savedpost'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              BlockedUsers(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.users,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'blockedusers'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      await OpenAppSettings
                                                          .openAppSettings();
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons
                                                                  .language,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(30.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'language'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SettingsForm(),
                                                        ),
                                                      );
                                                    },
                                                    child: new Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: ListTile(
                                                        leading: Container(
                                                          height:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          width:
                                                              kToolbarHeight /
                                                                  1.30,
                                                          child: Icon(
                                                              LineIcons.cog,
                                                              color:
                                                                  Colors.black),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                            // borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                        title: Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: 0),
                                                          child: Text(
                                                            AppLocalizations
                                                                .instance
                                                                .text(
                                                                    'advanceset'),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 15.3,
                                                                fontFamily:
                                                                    'SFProDisplayMedium'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Divider(
                                                    color: Color.fromRGBO(
                                                        224, 224, 224, 1),
                                                    height: 1,
                                                    thickness: 0,
                                                    indent: 20,
                                                    endIndent: 20,
                                                  ),
                                                ]))
                                      ]),
                                  Container(height: 10),
                                  ButtonTheme(
                                    //minWidth:
                                    //screenSize.width -45.8,
                                    height: 56.0,
                                    child: FlatButton(
                                        // splashColor: Colors.transparent,
                                        // highlightColor: Colors.transparent,
                                        child: Text(
                                          AppLocalizations.instance
                                              .text('cancel'),
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15.3,
                                              fontFamily: 'SFProDisplayMedium'),
                                        ),
                                        color: Colors.white,
                                        shape: new RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(
                                                    10.0)),
                                        onPressed: () {
                                          Navigator.pop(context);
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
                ))
              ]))
        : (isBlock(user.data.user.id) == true) ||
                (isBlocked(user.data.user.block) == true)
            ? Container()
            : Container(
                child: IconButton(
                icon: Icon(
                  Feather.user_x,
                  size: 26.0,
                  color: isShrink ? Colors.black : Colors.white,
                ),
                padding: EdgeInsets.only(right: 20.0, bottom: 1.3),
                onPressed: () {
                  this.blockuser(user.data.user.id);
                },
              ));
  }

  Widget buildProfileTitle(
      context, AsyncSnapshot<UserModel> user, int userowner) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.bottomLeft,
            child: Container(
              alignment: Alignment.bottomLeft,
              height: isShrink ? 0 : kToolbarHeight * 1,
              width: isShrink ? 0 : kToolbarHeight * 1,
              child: ClipRRect(
                borderRadius: new BorderRadius.circular(200.0),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: user.data.user.avatar,
                ),
              ),
            ),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(alignment: Alignment.bottomLeft, width: 10),
                      Container(
                        alignment: Alignment.bottomLeft,
                        margin: isShrink
                            ? EdgeInsets.only(left: 45, bottom: 2)
                            : EdgeInsets.only(
                                left: 0,
                              ),
                        transform: isShrink
                            ? Matrix4.translationValues(0.0, 1.5, 0.0)
                            : Matrix4.translationValues(0.0, 0.0, 0.0),
                        child: new Text(
                          user.data.user.name,
                          style: new TextStyle(
                            fontFamily: 'SFProDisplayBold',
                            fontSize: isShrink ? 19.5 : 14.5,
                            color: isShrink ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isShrink ? 4.5 : 3,
                      ),
                      user.data.user.badge == 'true'
                          ? Container(
                              alignment: Alignment.bottomLeft,
                              transform: isShrink
                                  ? Matrix4.translationValues(0, 5.5, 0.0)
                                  : Matrix4.translationValues(0, 2.7, 0.0),
                              padding: EdgeInsets.only(top: 1.5, bottom: 2.5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent),
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Icon(Icons.check_circle,
                                    size: isShrink ? 15.5 : 10.5,
                                    color:
                                        isShrink ? Colors.blue : Colors.white),
                              ),
                            )
                          : Container(
                              width: 0,
                            ),
                    ]),
                (user.data.user.bio == null)
                    ? Container(
                        width: 15,
                        height: isShrink ? 0 : 20,
                      )
                    : Container(
                        margin: isShrink
                            ? EdgeInsets.only(
                                left: 0,
                                bottom: 0,
                              )
                            : EdgeInsets.only(
                                left: 10,
                                bottom: 4,
                                top: 3,
                              ),
                        width: screenSize.width - 265,
                        child: Text(
                          user.data.user.bio,
                          textAlign: TextAlign.left,
                          style: new TextStyle(
                            fontSize: isShrink ? 0 : 9.2,
                            color: isShrink ? Colors.transparent : Colors.white,
                          ),
                        ),
                      ),
                user.data.user.badge == 'true'
                    ? new Column(children: <Widget>[
                        (user.data.user.link == null)
                            ? Container(height: 0)
                            : Container(
                                margin: isShrink
                                    ? EdgeInsets.only(
                                        left: 0, right: 0, top: 0, bottom: 0)
                                    : EdgeInsets.only(
                                        left: 10.0,
                                        right: 8.0,
                                        top: 0,
                                        bottom: 2),
                                transform:
                                    Matrix4.translationValues(0.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Feather.link,
                                      size: isShrink ? 0 : 9,
                                      color: isShrink
                                          ? Colors.transparent
                                          : Colors.white,
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        try {
                                          await launch(
                                              'https://' + user.data.user.link);
                                        } catch (e) {
                                          print(e);
                                        }
                                      },
                                      child: user.data.user.badge == 'true'
                                          ? new Column(
                                              children: <Widget>[
                                                (user.data.user.link == null)
                                                    ? Container()
                                                    : GestureDetector(
                                                        onTap: () async {
                                                          try {
                                                            await launch(
                                                                'https://' +
                                                                    user
                                                                        .data
                                                                        .user
                                                                        .link);
                                                          } catch (e) {
                                                            print(e);
                                                          }
                                                        },
                                                        child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left: 0.0,
                                                                  right: 8.0,
                                                                  top: 0),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15.0),
                                                            color: Colors
                                                                .transparent,
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 0.0,
                                                                    right: 0,
                                                                    bottom: 0,
                                                                    top: 0),
                                                            child: new Text(
                                                              ' ' +
                                                                  user.data.user
                                                                      .link,
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              style:
                                                                  new TextStyle(
                                                                fontFamily:
                                                                    'SFProDisplayMedium',
                                                                fontSize:
                                                                    isShrink
                                                                        ? 0
                                                                        : 9.0,
                                                                color: isShrink
                                                                    ? Colors
                                                                        .transparent
                                                                    : Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            )
                                          : Container(),
                                    ),
                                  ],
                                ),
                              ),
                      ])
                    : Container(),
              ]),
        ],
      ),
    );
  }

  Widget buildProfileImgHeader(
      context, AsyncSnapshot<UserModel> user, int userowner) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: 313,
      child: user.data.user.cover != null
          ? ShaderMask(
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
                  stops: [0.30, 0.30, 1.0, 0.5],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: user.data.user.cover,
              ))
          : Container(
              height: kToolbarHeight * 3,
              width: kToolbarHeight * 3,
              child: (widget.idController == 0 ||
                      widget.idController == global.userId)
                  ? Container(
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
                          ]))
                  : Container()),
    );
  }

  Widget buildProfileHeader(
      context, AsyncSnapshot<UserModel> user, int userowner) {
    final screenSize = MediaQuery.of(context).size;
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          SizedBox(
            height: 15.0,
          ),
          new Column(
            children: <Widget>[
              new Container(
                transform: Matrix4.translationValues(0.0, 0.0, 0.0),
                width: screenSize.width,
                margin: EdgeInsets.only(top: 0.0),
                child: new Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            //                   <--- left side
                            color: Color.fromRGBO(207, 207, 207, 1),
                            width: 1.0,
                          ),
                        ),
                      ),
                      width: screenSize.width / 3,
                      child: new Column(
                        children: <Widget>[
                          new Text(
                            user.data.user.following.toString(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                              fontFamily: 'SFProDisplaySemiBold',
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          new Text(
                            AppLocalizations.instance.text('following'),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontFamily: 'SFProDisplaySemiBold',
                                fontSize: 12.0,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: screenSize.width / 3,
                      child: new Column(
                        children: <Widget>[
                          new Text(
                            user.data.user.follower.toString(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                              fontFamily: 'SFProDisplaySemiBold',
                              fontSize: 16.0,
                            ),
                          ),
                          new Text(
                            AppLocalizations.instance.text('followers'),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontFamily: 'SFProDisplaySemiBold',
                                fontSize: 12.0,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            //                   <--- left side
                            color: Color.fromRGBO(207, 207, 207, 1),
                            width: 1.0,
                          ),
                        ),
                      ),
                      width: screenSize.width / 3,
                      child: new Column(
                        children: <Widget>[
                          new Text(
                            user.data.user.photocount.toString(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                              fontFamily: 'SFProDisplaySemiBold',
                              fontSize: 16.0,
                            ),
                          ),
                          new Text(
                            AppLocalizations.instance.text('post'),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontFamily: 'SFProDisplaySemiBold',
                                fontSize: 12.0,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 0,
              ),
            ],
          ),
          (isBlock(user.data.user.id) == true) ||
                  (isBlocked(user.data.user.block) == true)
              ? Column(children: <Widget>[
                  SizedBox(height: 15),
                  Divider(
                    color: Color.fromRGBO(207, 207, 207, 1),
                    height: 0,
                    thickness: 0,
                    indent: 0,
                    endIndent: 0,
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 13, top: 28),
                    child: Center(
                      child: Text(
                        AppLocalizations.instance.text('userblocked'),
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "SFProDisplayBold",
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ])
              : new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    (userowner == 0 || userowner == global.userId)
                        ? Container()
                        : Container(
                            margin: const EdgeInsets.only(top: 17, bottom: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                ButtonTheme(
                                  height: kToolbarHeight / 1.4,
                                  minWidth:
                                      MediaQuery.of(context).size.width / 2.15,
                                  child: FlatButton(
                                    color: (user.data.user.follow == "true")
                                        ? _colorforUnfollow
                                        : _colorforFollow,
                                    shape: new RoundedRectangleBorder(
                                        borderRadius:
                                            new BorderRadius.circular(5)),
                                    child: (user.data.user.follow == "true")
                                        ? Text(
                                            AppLocalizations.instance
                                                .text('unfollow'),
                                            style: new TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white,
                                                fontFamily:
                                                    'SFProDisplayRegular'),
                                          )
                                        : Text(
                                            AppLocalizations.instance
                                                .text('follow'),
                                            style: new TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.white,
                                                fontFamily:
                                                    'SFProDisplayRegular'),
                                          ),
                                    onPressed: () {
                                      setState(() {
                                        counterbus = 0;
                                      });
                                      (user.data.user.follow == "true")
                                          ? check().then(
                                              (internet) async {
                                                if (internet == false) {
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: new Text(
                                                          'Are you sure?',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'SFProDisplayBold',
                                                            fontSize: 23.5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        content: new Text(
                                                            "You won't be following this person anymore!"),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15.0),
                                                        ),
                                                        actions: <Widget>[
                                                          new FlatButton(
                                                            child:
                                                                new Text("No"),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          new FlatButton(
                                                            child:
                                                                new Text("Yes"),
                                                            onPressed:
                                                                () async {
                                                              await bloc
                                                                  .unfollowuser(
                                                                      userowner);
                                                              widget
                                                                  .notifyParent();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            )
                                          : check().then(
                                              (internet) async {
                                                if (internet == false) {
                                                } else {
                                                  bloc.followuser(userowner);
                                                  _fservice
                                                      .saveUserFollowFirestore(
                                                          userowner);
                                                }
                                              },
                                            );
                                      widget.notifyParent();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                ButtonTheme(
                                  height: kToolbarHeight / 1.4,
                                  minWidth:
                                      MediaQuery.of(context).size.width / 2.15,
                                  child: FlatButton(
                                    color: Color.fromRGBO(0, 141, 252, 1),
                                    shape: new RoundedRectangleBorder(
                                        borderRadius:
                                            new BorderRadius.circular(5)),
                                    child: new Text(
                                      AppLocalizations.instance.text('message'),
                                      style: new TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.white,
                                          fontFamily: 'SFProDisplayRegular'),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConversationSendForm(userowner),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
          SizedBox(
            height: 16.0,
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
