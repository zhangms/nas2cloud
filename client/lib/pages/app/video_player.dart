import 'package:flutter/material.dart';
import 'package:nas2cloud/api/api.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWapper extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWapper(this.videoUrl);

  @override
  State<VideoPlayerWapper> createState() => _VideoPlayerWapperState();
}

class _VideoPlayerWapperState extends State<VideoPlayerWapper> {
  late VideoPlayerController _controller;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(Api.signUrl(widget.videoUrl),
        httpHeaders: Api.httpHeaders());
    _controller
        .initialize()
        .onError((error, stackTrace) => print(error))
        .then((_) {
      setState(() {
        _controller.play();
      });
      _controller.addListener(() {
        if (isPlaying != _controller.value.isPlaying) {
          setState(() {
            isPlaying = _controller.value.isPlaying;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(alignment: Alignment.bottomCenter, children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                  ]),
                )
              : Container(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
