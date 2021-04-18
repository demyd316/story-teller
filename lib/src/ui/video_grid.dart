import 'package:cached_video_player/cached_video_player.dart';
import 'package:flutter/material.dart';

class VideoGrid extends StatefulWidget {
  final String url;

  const VideoGrid({Key key, this.url}) : super(key: key);
  @override
  _VideoClipState createState() => _VideoClipState();
}

class _VideoClipState extends State<VideoGrid> {
  CachedVideoPlayerController controller;

  bool showController = false;

  @override
  void initState() {
    controller = CachedVideoPlayerController.network(widget.url);
    controller.initialize().then((_) {
      setState(() {});
      controller.setLooping(true);
      controller.play();
      controller.setVolume(0);
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
        SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size?.width ?? 0,
          height: controller.value.size?.height ?? 0,
          child: CachedVideoPlayer(controller),
          ),
      ),
          ),
        Positioned.fill(
            child: Container(
                alignment: Alignment.topLeft,
                child: AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    decoration: new BoxDecoration(
                      color: new Color.fromRGBO(0, 0, 0, 0.66),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    width: 25,
                    height: 25,
                    margin: EdgeInsets.only(left: 14.5, top: 14.5),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Color.fromRGBO(255, 255, 255, 0.96),
                      size: 15,
                    ),
                  ),
                ))),
                
      ],
    );
  }
}
