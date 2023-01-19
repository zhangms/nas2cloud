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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(api.signUrl(widget.videoUrl),
        httpHeaders: api.httpHeaders());
    _controller
        .initialize()
        .onError((error, stackTrace) => print(error))
        .then((_) {
      setState(() {});
      _controller.play();
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
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
