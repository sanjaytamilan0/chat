import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utills/permission_handler.dart';
import 'agora_config.dart';

// Conditional import for Web Bridge (Native Stub vs Web Logic)
import 'web_bridge_stub.dart'
    if (dart.library.js) 'web_bridge_web.dart' as web_bridge;

class VideoCallPage extends StatefulWidget {
  final String channelId;
  final String remoteName;
  const VideoCallPage({super.key, required this.channelId, required this.remoteName});

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  RtcEngine? _engine;
  int _remoteUid = 0;
  bool _isJoined = false;
  bool _loading = true;
  
  // Controls state
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    // SMART DELAY (Web only): Give the internal plugin engine time to inject scripts
    if (kIsWeb) {
      debugPrint("SMART DELAY: Waiting 1.5 seconds for plugin scripts...");
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    // Request Permissions (Mobile only - Browser handles it automatically)
    if (!kIsWeb) {
      await AppPermissionHandler.requestAllPermissions();
    }
    
    // Initialize Agora
    await initializeAgora();
  }

  Future<void> initializeAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _isJoined = true;
            _loading = false;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("DEBUG: remote user $remoteUid joined the channel");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("DEBUG: remote user $remoteUid left channel. Reason: $reason");
          setState(() {
            _remoteUid = 0;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora error: $err, $msg');
        },
      ));

      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: '',
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint("Agora Initialization Error: $e");
      if (mounted) {
        _handleInitError(e.toString());
      }
    }
  }

  void _handleInitError(String error) {
    setState(() {
      _loading = false;
    });

    // Close this screen to prevent GetX loop
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Get.back();
    }

    // Show a clear error message
    Get.snackbar(
      "Call Error", 
      error.contains('createIrisApiEngine') ? 'Engine failed to initialize. Please refresh the page.' : error,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _engine?.muteLocalVideoStream(!_isVideoEnabled);
  }

  void _onSwitchCamera() {
    _engine?.switchCamera();
  }

  @override
  void dispose() {
    _endCallInFirestore();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _endCallInFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.channelId).update({
        'callingData.calling': false,
      });
    } catch (e) {
      debugPrint("Error ending call in firestore: $e");
    }
  }

  Future<void> _disposeAgora() async {
    if (_engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (e) {
        debugPrint("Error while disposing Agora: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.remoteName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Stack(
          children: [
            _localVideo(),
            if (_remoteUid != 0)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _remoteVideo(),
                  ),
                ),
              ),
            
            if (_remoteUid != 0)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Text("CONNECTED", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),

            // Call Controls Overlay
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "mute_mic",
                    mini: true,
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    child: Icon(_isMuted ? Icons.mic_off : Icons.mic, 
                               color: _isMuted ? Colors.red : Colors.white),
                    onPressed: _onToggleMute,
                  ),
                  
                  FloatingActionButton(
                    heroTag: "switch_camera",
                    mini: true,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: _onSwitchCamera,
                  ),

                  FloatingActionButton(
                    heroTag: "end_call",
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, size: 30, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  
                  FloatingActionButton(
                    heroTag: "toggle_video",
                    mini: true,
                    backgroundColor: !_isVideoEnabled ? Colors.white : Colors.white24,
                    child: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off, 
                               color: !_isVideoEnabled ? Colors.red : Colors.white),
                    onPressed: _onToggleVideo,
                  ),
                ],
              ),
            ),

            if (_loading)
               const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 20),
                    Text("Initializing Call...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            if (!_isVideoEnabled && !_loading)
              const Center(
                child: Text("Your video is off", 
                           style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _localVideo() {
    if (_engine != null && _isJoined && _isVideoEnabled) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return Container(color: Colors.black87);
    }
  }

  Widget _remoteVideo() {
    if (_engine != null && _remoteUid != 0) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Container(color: Colors.grey[900], 
                       child: const Icon(Icons.person, color: Colors.white, size: 40));
    }
  }
}
