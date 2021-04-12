import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:group_video_call_app/utilities/constant.dart';
import 'package:group_video_call_app/utilities/universalData.dart';
import 'package:permission_handler/permission_handler.dart';

class MeetingScreen extends StatefulWidget {
  RtcEngine _engine = null;

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<MeetingScreen> {
  String channelId = 'testChannelName';
  bool isJoined = false, switchCamera = true, switchRender = true;
  List<int> remoteUid = [];

  @override
  void initState() {
    super.initState();

    this._initEngine();
  }

  @override
  void dispose() {
    super.dispose();
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
    _joinChannel();
  }

  _addListeners() {
    widget._engine?.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        print('joinChannelSuccess ${channel} ${uid} ${elapsed}');
        print('________________JOin Success.___________________');
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
    await widget._engine?.joinChannel(
        '', channelId, UniversalData.username, Random().nextInt(2000));
  }

  _leaveChannel() async {
    await widget._engine?.leaveChannel();
    Navigator.pop(context);
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
    return Scaffold(
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: () => {_leaveChannel()},
          tooltip: 'End',
          child: Icon(Icons.call_end_sharp, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _renderVideo(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: MediaQuery.of(context).size.width),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox.fromSize(
                  size: Size(56, 56),
                  child: ClipOval(
                    child: MaterialButton(
                      color: Colors.blue,
                      padding: EdgeInsets.all(10.0),
                      onPressed: () {
                        this._switchCamera();
                      },
                      child:
                          Icon(Icons.flip_camera_android, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  _renderVideo() {
    return Expanded(
      flex: 1,
      child: Stack(
        children: [
          RtcLocalView.SurfaceView(),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, top: 80),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.of(remoteUid.map(
                    (e) => GestureDetector(
                      onTap: this._switchRender,
                      child: Container(
                        width: 120,
                        height: 200,
                        child: RtcRemoteView.SurfaceView(
                          uid: e,
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
