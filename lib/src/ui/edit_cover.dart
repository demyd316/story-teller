import 'dart:io';
import 'package:Storyteller/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Storyteller/src/models/user_model.dart';
import 'package:line_icons/line_icons.dart';
import 'dart:convert';
import '../blocs/profile_bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'dart:async';

import 'package:image_cropper/image_cropper.dart';

class EditCover extends StatefulWidget {
  @override
  StoryTellerEditProfile createState() => new StoryTellerEditProfile();
}

class StoryTellerEditProfile extends State<EditCover> {
  File _image;
  String name;
  String email;
  String bio;
  String link;
  String cover;
  bool isLoading = false;
  final GlobalKey<FormState> _formKey5 = GlobalKey<FormState>();

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
          bloc.fetchUser(0);
          bloc.userFetcherStatus.listen((onData) {}, onError: (_) {});
        }
      },
    );
  }

  @override
  void dispose() {
    bloc.dispose();

    super.dispose();
  }

  _cropImage(filePath) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        maxWidth: 1920,
        maxHeight: 1080,
        aspectRatioPresets: Platform.isAndroid
            ? [
                // CropAspectRatioPreset.square,
                //CropAspectRatioPreset.ratio3x2,
                //CropAspectRatioPreset.original,
                // CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                // CropAspectRatioPreset.original,
                // CropAspectRatioPreset.square,
                // CropAspectRatioPreset.ratio3x2,
                // CropAspectRatioPreset.ratio4x3,
                // CropAspectRatioPreset.ratio5x3,
                // CropAspectRatioPreset.ratio5x4,

                //CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        iosUiSettings: IOSUiSettings(
          //title: 'Crop Image',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          rectX: 1,
          rectY: 1,
          rectWidth: 1920,
          rectHeight: 1080,
          hidesNavigationBar: true,
          resetButtonHidden: true,
          minimumAspectRatio: 1.0,
          // rotateClockwiseButtonHidden: true,
        ));
    if (croppedImage != null) {
      _image = croppedImage;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Form(
      key: _formKey5,
      child: Scaffold(
        body: StreamBuilder(
          stream: bloc.userDetail,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {}
            if (snapshot.hasData) {
              return new Stack(
                children: [
                  CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: <Widget>[
                      SliverAppBar(
                        leading: Container(
                          transform: Matrix4.translationValues(5.0, 0.0, 0.0),
                          padding: EdgeInsets.only(left: 10.0, bottom: 0),
                          child: BackButton(),
                        ),
                        elevation: 1.0,
                        expandedHeight: kToolbarHeight,
                        pinned: true,
                        backgroundColor: Colors.white,
                        floating: true,
                        centerTitle: true,
                        title: Text(
                          AppLocalizations.instance.text('cover'),
                          style: TextStyle(
                            fontFamily: 'SFProDisplayBold',
                            fontSize: 25.0,
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            SizedBox(
                              height: 0.0,
                            ),
                            new Container(
                              width: screenSize.width,
                              child: new Align(
                                alignment: Alignment.center,
                                child: Column(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () async {
                                        PickedFile pickedFile =
                                            await ImagePicker().getImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 1920,
                                          maxHeight: 1080,
                                        );
                                        _cropImage(pickedFile.path);
                                      },
                                      child: (_image != null)
                                          ? new Container(
                                              width: double.infinity,
                                              height: 200,
                                              decoration: new BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(0.0),
                                                image: DecorationImage(
                                                  image: FileImage(_image),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                          : Stack(
                                              alignment: AlignmentDirectional
                                                  .topCenter,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      new BorderRadius.circular(
                                                          0.0),
                                                  child: Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      child: snapshot.data.user
                                                                  .cover !=
                                                              null
                                                          ? CachedNetworkImage(
                                                              fit: BoxFit.cover,
                                                              imageUrl: snapshot
                                                                  .data
                                                                  .user
                                                                  .cover,
                                                            )
                                                          : Container()),
                                                ),
                                                ClipRRect(
                                                  borderRadius:
                                                      new BorderRadius.circular(
                                                          0.0),
                                                  child: Container(
                                                    height: 200,
                                                    color: Color.fromRGBO(
                                                            0, 0, 0, 1)
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                Container(
                                                  height: 200,
                                                  child: Center(
                                                    child: Icon(
                                                      LineIcons.upload,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40.0,
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 60, right: 60),
                              child: Text(
                                AppLocalizations.instance.text('infocover'),
                                style: new TextStyle(
                                    color: Colors.black45,
                                    fontSize: 15.0,
                                    fontFamily: 'SFProDisplayRegular'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Stack(alignment: Alignment.center, children: [
                              Container(
                                margin: EdgeInsets.only(left: 0, right: 0),
                                width: screenSize.width - 25,
                                child: ButtonTheme(
                                  height: kToolbarHeight / 1.10,
                                  minWidth: screenSize.width - 25,
                                  child: FlatButton(
                                      color: Color.fromRGBO(0, 141, 252, 1),
                                      shape: new RoundedRectangleBorder(
                                          borderRadius:
                                              new BorderRadius.circular(10.0)),
                                      child: isLoading == false
                                          ? new Text(
                                              AppLocalizations.instance
                                                  .text('save'),
                                              style: new TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17.0,
                                                  fontFamily:
                                                      'SFProDisplayBold'),
                                            )
                                          : CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              valueColor:
                                                  new AlwaysStoppedAnimation<
                                                      Color>(Colors.white),
                                            ),
                                      onPressed: () async {
                                        try {
                                          if (_formKey5.currentState
                                                  .validate() ==
                                              true) {
                                            if (_image == null) {
                                              var userModel = User.editNoCover(
                                                (name != null)
                                                    ? name
                                                    : snapshot.data.user.name,
                                                (email != null)
                                                    ? email
                                                    : snapshot.data.user.email,
                                                (bio != null)
                                                    ? bio
                                                    : snapshot.data.user.bio,
                                                (link != null)
                                                    ? link
                                                    : snapshot.data.user.link,
                                              );
                                              setState(() {
                                                isLoading = true;
                                              });
                                              await bloc.editUser(userModel);
                                              savedShow();
                                              setState(() {
                                                isLoading = false;
                                              });
                                            } else {
                                              String base64Image = base64Encode(
                                                  _image.readAsBytesSync());
                                              var userModel = User.editCover(
                                                (name != null)
                                                    ? name
                                                    : snapshot.data.user.name,
                                                (email != null)
                                                    ? email
                                                    : snapshot.data.user.email,
                                                (bio != null)
                                                    ? bio
                                                    : snapshot.data.user.bio,
                                                (link != null)
                                                    ? link
                                                    : snapshot.data.user.link,
                                                base64Image,
                                              );
                                              setState(() {
                                                isLoading = true;
                                              });
                                              await bloc.editUser(userModel);
                                              setState(() {
                                                isLoading = true;
                                              });
                                              savedShow();
                                              setState(() {
                                                isLoading = false;
                                              });
                                            }
                                          }
                                        } catch (e) {
                                          print(e);
                                        }
                                      }),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
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
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
            );
          },
        ),
      ),
    );
  }

  void savedShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: new Text(
            AppLocalizations.instance.text('saved'),
            textAlign: TextAlign.center,
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
}
