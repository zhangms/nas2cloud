import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../api/api.dart';
import '../../pub/widgets.dart';

class VideoPlayerWapper extends StatefulWidget {
  final String videoUrl;
  final Map<String, String> requestHeader;

  VideoPlayerWapper(this.videoUrl, this.requestHeader);

  @override
  State<VideoPlayerWapper> createState() => _VideoPlayerWapperState();
}

class _VideoPlayerWapperState extends State<VideoPlayerWapper> {
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
            return AppWidgets.pageLoadingView();
          }
          VideoPlayerController controller = _getController(snapshot.data!);
          return Scaffold(
            body: Center(
              child: buildVideoView(),
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

  buildVideoView() {
    if (_controller == null) {
      return AppWidgets.centerTextView("Loading...");
    }
    if (_controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(alignment: Alignment.bottomCenter, children: [
          VideoPlayer(_controller!),
          VideoProgressIndicator(_controller!, allowScrubbing: true),
        ]),
      );
    }
    if (_controller!.value.hasError) {
      return AppWidgets.pageErrorView(
          _controller!.value.errorDescription ?? "ERROR");
    }
    return AppWidgets.centerTextView("Loading...");
  }
}
