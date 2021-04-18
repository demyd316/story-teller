import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:Storyteller/src/models/story_model.dart';
import 'package:story_view/story_view.dart';
import '../resources/story_teller_api_provider.dart';
import '../blocs/photos_bloc.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:cached_video_player/cached_video_player.dart';
import 'globals.dart' as global;
import 'keep_alive_page.dart';

class StoriesPreview extends StatelessWidget {
  final int toUserIdController;
  final String toUserNameController;
  final String toUserAvatarController;
  final String toUserBadgeController;
  StoriesPreview(this.toUserIdController, this.toUserNameController,
      this.toUserAvatarController, this.toUserBadgeController,
      {Key key10})
      : super(key: key10);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return PageView(controller: PageController(), children: <Widget>[
      KeepAlivePage(
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.grey,
          body: FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return StoryViewDelegate(
                  stories: snapshot.data,
                  userId: toUserIdController,
                  userAvatar: toUserAvatarController,
                  userName: toUserNameController,
                  userBadge: toUserBadgeController,
                );
              }
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }

              return Container(
                width: screenSize.width,
                height: screenSize.height,
                child: Shimmer(
                  duration: Duration(seconds: 1), //Default value
                  interval: Duration(
                      seconds: 1), //Default value: Duration(seconds: 0)
                  color: Colors.black, //Default value
                  enabled: true, //Default value
                  direction: ShimmerDirection.fromLTRB(), //Default Value
                  child: Container(
                    width: screenSize.width,
                    height: screenSize.height,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: new BorderRadius.circular(15),
                    ),
                  ),
                ),
              );
            },
            future: StoryTellerApiProvider.getStories(toUserIdController),
          ),
        ),
      ),
      
    ]);
  }
}

Duration parseDuration(String s) {
  int hours = 0;
  int minutes = 0;
  int micros;
  List<String> parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}

class StoryViewDelegate extends StatefulWidget {
  final List<Story> stories;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userBadge;
  StoryViewDelegate(
      {this.stories,
      this.userId,
      this.userName,
      this.userAvatar,
      this.userBadge});
  @override
  _StoryViewDelegateState createState() => _StoryViewDelegateState();
}

class _StoryViewDelegateState extends State<StoryViewDelegate> {
  CachedVideoPlayerController vcontroller;
  bool showController = false;

  final StoryController controller = StoryController();
  List<StoryItem> storyItems = [];
  int _id;
  int pos;
  String when;
  bool user = false;
  @override
  void initState() {
    vcontroller =
        CachedVideoPlayerController.network(widget.stories.first.path);
    vcontroller.initialize().then((_) {
      setState(() {});

      vcontroller.setLooping(true);
      vcontroller.play();
      vcontroller.setVolume(0);
    });
    super.initState();
    when = widget.stories[0].createdAt;

    bloc.fetchUser(0);
    bloc.userDetail.listen(
      (data) {
        if (data != null) {
          if (user == true) {
            global.userId = data.user.id;
            user = false;
          }
        }
      },
    );
    widget.stories.forEach((story) {
      if (story.type == 'video') {
        storyItems.add(
          
          StoryItem.pageVideo(
            story.path,
            controller: controller,
            imageFit: BoxFit.cover,
            duration: parseDuration(story.duration),
          ),
        );
      }

      if (story.type == 'image') {
        storyItems.add(
          
          StoryItem.pageImage(
            url: story.path,
            imageFit: BoxFit.cover,
            controller: controller,
            duration: parseDuration(story.duration),
          ),
        );
      }
    });
  }

  refresh() {}

  @override
  void dispose() {
    vcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return  Stack(
      children: [
        widget.stories.first.type == 'video'
            ?  SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: vcontroller.value.size?.width ?? 0,
          height: vcontroller.value.size?.height ?? 0,
          child: CachedVideoPlayer(vcontroller),
          ),
      ),
          )
                
              
            : CachedNetworkImage(
                    height: screenSize.height,
                    width: screenSize.width,
                    fit: BoxFit.cover,
                    placeholder: (c, d) {
                      return Center();
                    },
                    imageUrl: widget.stories.first.path,
                  ),
               
      ],
    );
  }
}
