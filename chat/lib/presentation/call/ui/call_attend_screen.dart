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
  String _statusMessage = "Initializing...";
  
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
          if (mounted) {
            setState(() {
              _isJoined = true;
              _loading = false;
              _statusMessage = "Joined";
            });
          }
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint("Connection state changed: $state, reason: $reason");
          if (mounted) {
            setState(() {
              _statusMessage = state.name.replaceAll('connectionState', '');
            });
            if (state == ConnectionStateType.connectionStateFailed) {
              _handleInitError("Connection failed: $reason");
            }
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("DEBUG: remote user $remoteUid joined the channel");
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("DEBUG: remote user $remoteUid left channel. Reason: $reason");
          if (mounted) {
            setState(() {
              _remoteUid = 0;
            });
          }
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora error: $err, $msg');
          if (mounted) {
            _handleInitError("$err: $msg");
          }
        },
      ));

      await _engine!.enableVideo();
      await _engine!.startPreview();

      await _engine!.joinChannel(
        token: AgoraConfig.token,
        channelId: "videochat",
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black, // Still black for video contrast
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
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _remoteVideo(),
                  ),
                ),
              ),
            
            if (_remoteUid != 0)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text("CONNECTED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            // Call Controls Overlay
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                      onPressed: _onToggleMute,
                      label: "Mute",
                    ),
                    _buildControlButton(
                      icon: Icons.cameraswitch,
                      color: Colors.white,
                      onPressed: _onSwitchCamera,
                      label: "Switch",
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.call_end, size: 32, color: Colors.white),
                      ),
                    ),
                    _buildControlButton(
                      icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: !_isVideoEnabled ? Colors.red : Colors.white,
                      onPressed: _onToggleVideo,
                      label: "Video",
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
                Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            if (!_isVideoEnabled && !_loading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, size: 64, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text("Your video is off", 
                               style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onPressed, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 28),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _localVideo() {
    if (_engine != null && _isVideoEnabled) {
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
