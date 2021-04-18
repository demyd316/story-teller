import 'package:Storyteller/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import '../blocs/search_main_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/image_model.dart';
import 'package:Storyteller/src/ui/video_grid.dart';
import 'package:Storyteller/src/ui/search_grid_detail.dart';
import 'package:Storyteller/src/ui/profile.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'dart:async';
import 'package:mime/mime.dart';
import 'globals.dart' as global;
import 'package:flutter_icons/flutter_icons.dart' as ico;
import 'dart:math' as math;
import 'package:Storyteller/src/ui/comments.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:progress_indicators/progress_indicators.dart';

import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:Storyteller/src/resources/firebase_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchTabPhotoGrid extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<SearchTabPhotoGrid>
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
              child: StaggeredGridView.countBuilder(
                padding: const EdgeInsets.all(0),
                crossAxisCount: 4,
                itemCount: snapshot.data.data.length,
                itemBuilder: (context, int index) {
                  return (isBlock(snapshot.data.data[index].user.data.id) ==
                              true) ||
                          (isBlocked(
                                  snapshot.data.data[index].user.data.block) ==
                              true)
                      ? Container()
                      : GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchTabPhoto(index)));
                          },
                          child:
                              checkFileType(snapshot.data.data[index].image) ==
                                      "image"
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        imageUrl:
                                            snapshot.data.datas[index].image,
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: VideoGrid(
                                          url: snapshot.data.data[index].image),
                                    ));
                },
                staggeredTileBuilder: (index) =>
                    StaggeredTile.count(2, index.isEven ? 2 : 3),
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
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
