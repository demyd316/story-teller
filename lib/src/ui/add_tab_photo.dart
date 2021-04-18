import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:image_cropper/image_cropper.dart';
import 'package:Storyteller/app_localizations.dart';
import 'package:Storyteller/src/constant/httpService.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:Storyteller/src/constant/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:wc_form_validators/wc_form_validators.dart';
import '../blocs/photos_bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:async/async.dart';

import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:hashtagable/hashtagable.dart';

class TabPhoto extends StatefulWidget {
  @override
  StoryTellerAddPhoto createState() => new StoryTellerAddPhoto();
}

class StoryTellerAddPhoto extends State<TabPhoto> {
  final baseUrl = "${NetworkUtils.urlBase}${NetworkUtils.serverApi}";

  File _media;
  bool isVideo = false;
  bool isLoading = false;
  VideoPlayerController _controller;
  CameraController _controlleri;

  TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey3 = GlobalKey<FormState>();
  bool up = false;
  List<String> main = List();

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
  void initState() {
    super.initState();
    check().then(
      (internet) {
        if (internet == false) {
        } else {
          bloc.photoFetcherStatus.listen((onData) {});
        }
      },
    );
    Timer.run(
      () async {
        PickedFile pickedFile = await ImagePicker().getImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
        );
        _cropImage(pickedFile.path);
      },
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    _controlleri.dispose();
    super.dispose();
  }

  void downloading() {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        padding: EdgeInsets.only(bottom: 5, top: 5),
        margin: EdgeInsets.only(bottom: 13, left: 13, right: 13),
        elevation: 0,
        backgroundColor: Color.fromRGBO(78, 187, 31, 1),
        content: Text(
          AppLocalizations.instance.text('downloading'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        duration: Duration(milliseconds: 2200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double bottomBarHeight = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Form(
        key: _formKey3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: false,
              title: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  AppLocalizations.instance.text('addpost'),
                  style: TextStyle(
                    fontFamily: 'SFProDisplayBold',
                    fontSize: 25.0,
                  ),
                ),
              ),
              actions: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: EdgeInsets.only(bottom: 13.0, top: 13.0),
                      child: ButtonTheme(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        height: kToolbarHeight / 1.10,
                        minWidth: 60,
                        child: FlatButton(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          color: Colors.white,
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(6.0)),
                          child: Text(
                            AppLocalizations.instance.text('cancel'),
                            style: new TextStyle(
                                color:
                                    _media == null ? Colors.grey : Colors.grey,
                                fontSize: 15.0,
                                fontFamily: 'SFProDisplayMedium'),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                )
              ]),
          body: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                  top: 10,
                  //  bottom: bottomBarHeight + 90,
                  left: 5,
                  right: 5,
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 0.0, right: 0.0),
                  child: Column(children: <Widget>[
                    TextFormField(
                      inputFormatters: [
                        new LengthLimitingTextInputFormatter(80),
                      ],
                      controller: descriptionController,
                      keyboardType: TextInputType.text,
                      minLines: 1,
                      autofocus: true,
                      maxLines: 2,
                      maxLength: 80,
                      validator: Validators.compose([
                        Validators.required(AppLocalizations.instance.text('requireddescri'),),
                        Validators.minLength(
                            0, 'Description cannot be less than 10 characters'),
                        Validators.maxLength(200,
                            'Description cannot be greater than 200 characters'),
                      ]),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.instance.text('writehere'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        contentPadding:
                            EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
                      ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Divider(
                      color: Color.fromRGBO(207, 207, 207, 1),
                      height: 1,
                      thickness: 0,
                      indent: 0,
                      endIndent: 0,
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 0, right: 0),
                      width: screenSize.width - 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        color: Colors.transparent,
                      ),
                      child: _media == null
                          ? Center()
                          : GestureDetector(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: isVideo == false
                                    ? Image.file(
                                        _media,
                                        fit: BoxFit.cover,
                                      )
                                    : _controller.value.initialized
                                        ? AspectRatio(
                                            aspectRatio:
                                                _controller.value.aspectRatio,
                                            child: VideoPlayer(_controller),
                                          )
                                        : Center(
                                            child: CircularProgressIndicator(),
                                          ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                    _controller.setVolume(1);
                                  }
                                });
                              },
                            ),
                    ),
                    isVideo == true
                        ? GestureDetector(
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 50,
                              color: Colors.white,
                            ),
                            onTap: () {
                              setState(() {
                                if (_controller.value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                  _controller.setVolume(1);
                                }
                              });
                            },
                          )
                        : Container(),
                    SizedBox(
                      height: 5.0,
                    ),
                  ]),
                ),
              ),
              Positioned(
                left: 0.0,
                bottom: bottomBarHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Color.fromRGBO(224, 224, 224, 1),
                        width: 0.60,
                      ),
                    ),
                  ),
                  width: screenSize.width,
                  height: 52,
                ),
              ),
              Positioned(
                right: 19.0,
                bottom: bottomBarHeight + 8,
                child: Container(
                  width: 90,
                  height: 35,
                  child: ButtonTheme(
                    height: kToolbarHeight / 1.10,
                    minWidth: screenSize.width - 80,
                    child: FlatButton(
                        color: Colors.transparent,
                        shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(5.0)),
                        child: isLoading == false
                            ? new Text(
                                AppLocalizations.instance.text('publish'),
                                style: new TextStyle(
                                    color: _media == null
                                        ? Colors.grey
                                        : Colors.blue,
                                    fontSize: 15.0,
                                    fontFamily: 'SFProDisplaySemiBold'),
                              )
                            : CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: new AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                        onPressed: () {
                          check().then((internet) async {
                            if (internet == false) {
                            } else {
                              if (_formKey3.currentState.validate() == true) {
                                if (_media == null) return;
                                setState(() {
                                  isLoading = true;
                                });
                                sendUploadFile(descriptionController.text);
                                Navigator.pop(context);
                              }
                            }
                          });
                        }),
                  ),
                ),
              ),
              Positioned(
                left: 19.0,
                bottom: bottomBarHeight + 8,
                child: Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    color: Colors.white,
                  ),
                  child: Container(
                    transform: Matrix4.translationValues(-2, -4, 0.0),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(Feather.camera),
                      iconSize: 23.0,
                      color: Colors.green,
                      onPressed: () {
                        isVideo = false;
                        _getImage();
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 68.0,
                bottom: bottomBarHeight + 8,
                child: Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    color: Colors.white,
                  ),
                  child: Container(
                    transform: Matrix4.translationValues(-2, -3, 0.0),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(Feather.video),
                      iconSize: 23.0,
                      color: Colors.deepPurpleAccent,
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
                                  _controller.setLooping(true);
                                  _controller.play();
                                  _controller.setVolume(0);
                                },
                              );
                          });
                          isVideo = true;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void savedShow() {
    Navigator.pop(context);
  }

  void checkMediaType() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(
            AppLocalizations.instance.text('fromwhere'),
            style: TextStyle(
              fontFamily: 'SFProDisplayBold',
              fontSize: 23.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: new Text(
            AppLocalizations.instance.text('selectfile'),
            textAlign: TextAlign.left,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.pop(context);
                isVideo = false;
                _getImage();
              },
              child: new Text(
                AppLocalizations.instance.text('image'),
              ),
            ),
            new FlatButton(
              onPressed: () {
                Navigator.pop(context);
                isVideo = true;
                _getVideo();
              },
              child: new Text(
                AppLocalizations.instance.text('video'),
              ),
            )
          ],
        );
      },
    );
  }

  _getImage() async {
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
                          maxWidth: 1800,
                          maxHeight: 1800,
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
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text(
              AppLocalizations.instance.text('video'),
              style: TextStyle(
                fontFamily: 'SFProDisplayBold',
                fontSize: 23.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: new Text(
              "Now open the gallery, choose your video and upload it to teling.",
              style: TextStyle(
                fontFamily: 'SFProDisplayRegular',
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            actions: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new FlatButton(
                      child: new Text(
                        AppLocalizations.instance.text('gallery'),
                        style: TextStyle(
                          fontFamily: 'SFProDisplayMedium',
                          color: Color.fromRGBO(0, 141, 252, 1),
                        ),
                      ),
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
                                  _controller.setLooping(true);
                                  _controller.play();
                                  _controller.setVolume(0);
                                },
                              );
                          });
                         isVideo = true;
                        });
                      },
                    ),
                    FlatButton(
                      child: new Text(
                        "Camera",
                        style: TextStyle(
                          fontFamily: 'SFProDisplayMedium',
                          color: Color.fromRGBO(0, 141, 252, 1),
                        ),
                      ),
                      onPressed: () async {
                        Future<File> video2 =
                            ImagePicker.pickVideo(source: ImageSource.camera);

                        video2.then((file) async {
                          setState(() {
                            _media = file;
                            _controller = VideoPlayerController.file(_media)
                              ..initialize().then(
                                (_) {
                                  setState(() {});
                                  _controller.setLooping(true);
                                },
                              );
                          });
                          Navigator.pop(context);
                        });
                      },
                    ),
                    new FlatButton(
                      child: new Text(
                        AppLocalizations.instance.text('cancel'),
                        style: TextStyle(
                          fontFamily: 'SFProDisplayMedium',
                          color: Color.fromRGBO(0, 141, 252, 1),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ]),
            ],
          );
        },
      );
    } catch (error) {}
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        maxWidth: 1080,
        maxHeight: 1080,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                //CropAspectRatioPreset.ratio3x2,
                //CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                // CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,

                //CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        iosUiSettings: IOSUiSettings(
          //title: 'Crop Image',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          rectX: 1,
          rectY: 1,
          rectWidth: 1080,
          rectHeight: 1080,
          hidesNavigationBar: true,
          //resetButtonHidden: true,
          minimumAspectRatio: 1.0,
          // rotateClockwiseButtonHidden: true,
        ));
    if (croppedImage != null) {
      _media = croppedImage;
      setState(() {
        //  Navigator.pop(context);
      });
    }
  }

  Future<String> fetchToken() async {
    var client = await HttpService().getClient();
    return client.credentials.accessToken.toString();
  }

  void sendUploadFile(String description) async {
    final String url = "${NetworkUtils.urlBase}${NetworkUtils.serverApi}posts";

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
        'image', stream_video, length_video,
        filename: path.basename(_media.path));

    request.files.add(multipartFile);
    request.fields['id'] = "1";
    request.fields['user_id'] = "1";
    request.fields['likes'] = "1";
    request.fields['description'] = description;

    request.headers.addAll(headers);
    var response = await request.send();
    print(response.statusCode);
    setState(() {
      isLoading = false;
    });

    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
    });
  }
}
