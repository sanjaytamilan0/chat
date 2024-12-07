import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  final String channelId;

  VideoCallPage({required this.channelId});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late RtcEngine _engine;
  int _remoteUid = 0;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  // Initialize Agora Engine
  Future<void> initializeAgora() async {
    _engine = await RtcEngine.create('YOUR_AGORA_APP_ID'); // Use your Agora App ID
    await _engine.enableVideo();

    // Set event handlers for Agora
    _engine.setEventHandler(RtcEngineEventHandler(
      userJoined: (int uid, int elapsed) {
        print('User $uid has joined the channel');
        setState(() {
          _remoteUid = uid;
        });
      },
      userOffline: (int uid, UserOfflineReason reason) {
        print('User $uid has left the channel');
        setState(() {
          _remoteUid = 0;
        });
      },
      error: (dynamic code) {
        print('Agora error: $code');
      },
    ));

    // Join the channel
    await _engine.joinChannel(null, widget.channelId, null, 0);
  }

  @override
  void dispose() {
    super.dispose();
    _engine.leaveChannel();
    _engine.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call')),
      body: Center(
        child: Stack(
          children: [
            // Local user video view
            AgoraVideoView(uid: 0, isLocal: true),
            // Remote user video view, shown only if a remote user has joined
            if (_remoteUid != 0) AgoraVideoView(uid: _remoteUid, isLocal: false),
            Positioned(
              bottom: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.call_end, color: Colors.red, size: 40),
                onPressed: () {
                  // Handle end call
                  _engine.leaveChannel();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgoraVideoView extends StatelessWidget {
  final int uid;
  final bool isLocal;

  AgoraVideoView({required this.uid, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLocal ? 150 : double.infinity,
      height: isLocal ? 150 : double.infinity,
      child: isLocal
          ? AgoraVideoView(uid: uid, isLocal: isLocal)// Local user view
          : AgoraVideoView(uid: uid, isLocal: isLocal) // Remote user view
    );
  }
}
