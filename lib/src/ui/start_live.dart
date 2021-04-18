import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:Storyteller/app_localizations.dart';
import 'package:flutter_icons/flutter_icons.dart' as ico;
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:video_player/video_player.dart';

class LivePage extends StatefulWidget {
  @override
  StoryTellerSettings createState() => new StoryTellerSettings();
}

class StoryTellerSettings extends State<LivePage> {
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
  }

  void checkLiveType() {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(33, 33, 33, 1),
          title: Center(
            child: Column(children: <Widget>[
              SizedBox(height: 5),
              Text(
                'Live',
                style: TextStyle(
                  fontFamily: 'SFProDisplayBold',
                  fontSize: 20.5,
                  color: Colors.white,
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
                    color: Colors.white,
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
                SizedBox(height: 10),
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
                          color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withOpacity(0.30),
                  Colors.black.withOpacity(0.30),
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.10),
                ],
                stops: [0.0, 0.0, 0.0, 0.0],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://media2.giphy.com/media/2tLxESSCMiBKeK4Cpl/giphy.gif",
                    placeholder: (context, url) => Container(),
                    errorWidget: (context, url, error) => Container(),
                  ),
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: kToolbarHeight,
                pinned: true,
                floating: true,
                centerTitle: true,
                title: Icon(ico.Feather.radio, color: Colors.red, size: 39),
                automaticallyImplyLeading: false,
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SizedBox(
                      height: 0,
                    ),
                    SizedBox(height: 28),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('readylive'),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontFamily: 'SFProDisplayBold'),
                      ),
                    ),
                    SizedBox(height: 25),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 100),
                      child: Text(
                        AppLocalizations.instance.text('readylive1'),
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 55),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Row(children: <Widget>[
                        Icon(ico.MaterialCommunityIcons.tshirt_crew,
                            color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          AppLocalizations.instance.text('readyliveno1'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.3,
                              fontFamily: 'SFProDisplayRegular'),
                        ),
                      ]),
                    ),
                    SizedBox(height: 35),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Row(children: <Widget>[
                        Icon(ico.MaterialCommunityIcons.kabaddi,
                            color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          AppLocalizations.instance.text('readyliveno2'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.3,
                              fontFamily: 'SFProDisplayRegular'),
                        ),
                      ]),
                    ),
                    SizedBox(height: 35),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Row(children: <Widget>[
                        Icon(ico.MaterialCommunityIcons.sword_cross,
                            color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          AppLocalizations.instance.text('readyliveno3'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.3,
                              fontFamily: 'SFProDisplayRegular'),
                        ),
                      ]),
                    ),
                    SizedBox(height: 35),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Row(children: <Widget>[
                        Icon(ico.MaterialCommunityIcons.bacteria_outline,
                            color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          AppLocalizations.instance.text('readyliveno4'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.3,
                              fontFamily: 'SFProDisplayRegular'),
                        ),
                      ]),
                    ),
                    SizedBox(height: 35),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Row(children: <Widget>[
                        Icon(ico.MaterialCommunityIcons.baby_face_outline,
                            color: Colors.white),
                        SizedBox(width: 20),
                        Text(
                          AppLocalizations.instance.text('readyliveno5'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.3,
                              fontFamily: 'SFProDisplayRegular'),
                        ),
                      ]),
                    ),
                    SizedBox(height: 65),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('readyliveno7'),
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 40),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Container(
                        margin: EdgeInsets.only(left: 0, right: 0),
                        width: screenSize.width - 25,
                        child: ButtonTheme(
                          height: kToolbarHeight / 1.10,
                          minWidth: screenSize.width - 25,
                          child: FlatButton(
                              color: Colors.red,
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0)),
                              child: Text(
                                'Go Live',
                                style: new TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.0,
                                    fontFamily: 'SFProDisplaySemiBold'),
                              ),
                              onPressed: () {
                                checkLiveType();
                              }),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Container(
                        margin: EdgeInsets.only(left: 0, right: 0),
                        width: screenSize.width - 25,
                        child: ButtonTheme(
                          height: kToolbarHeight / 1.10,
                          minWidth: screenSize.width - 25,
                          child: FlatButton(
                              color: Colors.transparent,
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(5.0)),
                              child: Text(
                                AppLocalizations.instance.text('cancel'),
                                style: new TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.0,
                                    fontFamily: 'SFProDisplayMedium'),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
