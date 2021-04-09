import 'dart:developer';
import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:group_video_call_app/utilities/constant.dart';
import 'package:permission_handler/permission_handler.dart';

class MeetingScreen extends StatefulWidget {
  RtcEngine _engine = null;

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<MeetingScreen> {
  String channelId = CHANNEL1;
  bool isJoined = false, switchCamera = true, switchRender = true;
  List<int> remoteUid = [];
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: channelId);
    this._initEngine();
  }

  @override
  void dispose() {
    super.dispose();
    this._leaveChannel();
    widget._engine?.destroy();
  }

  _initEngine() async {
    widget._engine =
        await RtcEngine.createWithConfig(RtcEngineConfig(AGORA_APP_ID));
    this._addListeners();

    await widget._engine.enableVideo();
    await widget._engine.startPreview();

    await widget._engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await widget._engine.setClientRole(ClientRole.Broadcaster);
  }

  _addListeners() {
    widget._engine?.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        print('joinChannelSuccess ${channel} ${uid} ${elapsed}');
        setState(() {
          isJoined = true;
        });
      },
      userJoined: (uid, elapsed) {
        print('userJoined  ${uid} ${elapsed}');
        setState(() {
          remoteUid.add(uid);
        });
      },
      userOffline: (uid, reason) {
        print('userOffline  ${uid} ${reason}');
        setState(() {
          remoteUid.removeWhere((element) => element == uid);
        });
      },
      leaveChannel: (stats) {
        print('leaveChannel ${stats.toJson()}');
        setState(() {
          isJoined = false;
          remoteUid.clear();
        });
      },
    ));
  }

  _joinChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    await widget._engine
        ?.joinChannel(AGORA_TOKEN, channelId, null, Random().nextInt(100));
  }

  _leaveChannel() async {
    await widget._engine?.leaveChannel();
  }

  _switchCamera() {
    widget._engine?.switchCamera()?.then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    })?.catchError((err) {
      print('switchCamera $err');
    });
  }

  _switchRender() {
    setState(() {
      switchRender = !switchRender;
      remoteUid = List.of(remoteUid.reversed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _renderVideo(),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MaterialButton(
                color: Colors.deepPurple,
                onPressed: this._switchCamera,
                child: Text('Camera ${switchCamera ? 'switch' : 'switch'}'),
              ),
              SizedBox(height: 30),
              SizedBox(width: MediaQuery.of(context).size.width),
              MaterialButton(
                color: isJoined ? Colors.red : Colors.green,
                onPressed: isJoined ? this._leaveChannel : this._joinChannel,
                child: Text('${isJoined ? 'End Call' : 'Start Call'}'),
              ),
              SizedBox(height: 30),
            ],
          ),
        )
      ],
    );
  }

  _renderVideo() {
    return Expanded(
      child: Stack(
        children: [
          RtcLocalView.SurfaceView(),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, top: 50.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.of(remoteUid.map(
                    (e) => GestureDetector(
                      onTap: this._switchRender,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 120,
                          height: 120,
                          child: RtcRemoteView.SurfaceView(
                            uid: e,
                          ),
                        ),
                      ),
                    ),
                  )),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
