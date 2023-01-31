import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:nas2cloud/themes/widgets.dart';
import 'package:video_player/video_player.dart';

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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: initVideoPlayerController(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AppWidgets.getPageLoadingView();
          }
          return Scaffold(
            body: Center(
              child: _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child:
                          Stack(alignment: Alignment.bottomCenter, children: [
                        VideoPlayer(_controller!),
                        VideoProgressIndicator(_controller!,
                            allowScrubbing: true),
                      ]),
                    )
                  : Container(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          );
        });
  }

  Future<void> initVideoPlayerController() async {
    var url = await Api.signUrl(widget.videoUrl);
    _controller =
        VideoPlayerController.network(url, httpHeaders: widget.requestHeader);
    await _controller!
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
  }
}
