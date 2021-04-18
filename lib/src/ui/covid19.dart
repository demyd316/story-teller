import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:Storyteller/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Covid19 extends StatefulWidget {
  @override
  StoryTellerSettings createState() => new StoryTellerSettings();
}

class StoryTellerSettings extends State<Covid19> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0.8,
                  expandedHeight: kToolbarHeight,
                  pinned: true,
                  floating: true,
                  title: Text(
                    AppLocalizations.instance.text('covidtitle'),
                    style: TextStyle(
                      fontFamily: 'SFProDisplayBold',
                      fontSize: 16.0,
                    ),
                  ),
                  centerTitle: true,
                  leading: Container(
                    transform: Matrix4.translationValues(5.0, 0.0, 0.0),
                    padding: EdgeInsets.only(left: 10.0, bottom: 0),
                    child: BackButton(
                      color: Colors.black,
                    ),
                  )),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SizedBox(
                      height: 0,
                    ),
                    Container(
                      //  width: 90,
                      height: 200,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://media.chelseapiers.com/images/cp/2020/misc/cp-covid-icons-simple-child-masks.png",
                        placeholder: (context, url) => new Container(),
                        errorWidget: (context, url, error) =>
                            new Icon(Icons.error),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line1'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayBold'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line2'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line3'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line4'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line5'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line6'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line7'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line8'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line10'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayBold'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line11'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line12'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line13'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line14'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line15'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line16'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 15),
                    Padding(
                      padding: new EdgeInsets.only(left: 20.0, right: 20),
                      child: Text(
                        AppLocalizations.instance.text('line17'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.3,
                            fontFamily: 'SFProDisplayRegular'),
                      ),
                    ),
                    SizedBox(height: 45),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
