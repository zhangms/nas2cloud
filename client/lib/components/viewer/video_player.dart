import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../api/api.dart';
import '../../pub/widgets.dart';

class VideoPlayerWrapper extends StatefulWidget {
  final String videoUrl;
  final Map<String, String> requestHeader;

  VideoPlayerWrapper(this.videoUrl, this.requestHeader);

  @override
  State<VideoPlayerWrapper> createState() => _VideoPlayerWrapperState();
}

class _VideoPlayerWrapperState extends State<VideoPlayerWrapper> {
  VideoPlayerController? _controller;

  bool isPlaying = false;

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: getVideoSignUrl(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          VideoPlayerController controller = _getController(snapshot.data!);
          return Scaffold(
            body: Center(
              child: buildVideoView(controller),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          );
        });
  }

  Future<String> getVideoSignUrl() async {
    return await Api().signUrl(widget.videoUrl);
  }

  VideoPlayerController _getController(String url) {
    if (_controller != null) {
      return _controller!;
    }
    _controller =
        VideoPlayerController.network(url, httpHeaders: widget.requestHeader);
    _controller!
        .initialize()
        .onError((error, stackTrace) => print(error))
        .then((_) {
      setState(() {
        _controller!.play();
      });
      _controller!.addListener(() {
        if (isPlaying != _controller!.value.isPlaying) {
          setState(() {
            isPlaying = _controller!.value.isPlaying;
          });
        }
      });
    });
    return _controller!;
  }

  Widget buildVideoView(VideoPlayerController controller) {
    if (controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          VideoPlayer(controller),
          VideoProgressIndicator(controller, allowScrubbing: true),
        ]),
      );
    }
    if (controller.value.hasError) {
      return AppWidgets.pageErrorView(
          controller.value.errorDescription ?? "ERROR");
    }
    return AppWidgets.pageLoadingView();
  }
}
