import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:line_icons/line_icons.dart';

class VideoClip extends StatefulWidget {
  final String url;

  const VideoClip({Key key, this.url}) : super(key: key);
  @override
  _VideoClipState createState() => _VideoClipState();
}

class _VideoClipState extends State<VideoClip> {
  CachedVideoPlayerController controller;

  bool showController = false;

  @override
  void initState() {
    controller = CachedVideoPlayerController.network(widget.url);
    controller.initialize().then((_) {
      setState(() {});
  
      controller.setVolume(0);
      controller.setLooping(true);
      controller.play();
    });
    super.initState();
    print("Controller **************" + controller.toString());
    print("url *****************" + widget.url);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: 370,
            minWidth: 370,
          ),
          color: Colors.transparent,
          child: Center(
            child: controller.value.initialized
                ? SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size?.width ?? 0,
          height: controller.value.size?.height ?? 0,
          child: CachedVideoPlayer(controller),
          ),
      ),
          )
                : Container(
                    height: 250,
                    width: 250,
                  ),
          ),
        ),
        
      ],
    );
  }
}
