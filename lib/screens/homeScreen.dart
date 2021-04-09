import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:group_video_call_app/screens/meetingScreen.dart';
import 'package:group_video_call_app/utilities/universalData.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController userNameController = TextEditingController();
  String dropdownValue = '1';
  bool isSwitched = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(userNameController, 'User Name'),
                SizedBox(height: 20),
                _videoSwitch(),
                SizedBox(height: 20),
                _joinButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildTextField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.blue[100],
        ),
        child: TextField(
          textInputAction: TextInputAction.done,
          controller: controller,
          cursorColor: Colors.black,
          maxLines: 1,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              labelText: labelText,
              labelStyle: TextStyle(color: Colors.black26),
              border: InputBorder.none),
        ),
      ),
    );
  }

  MaterialButton _joinButton() {
    return MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      height: 50,
      onPressed: () => joinGroup(),
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Join',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _videoSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Video:'),
        SizedBox(width: 20),
        Switch(
          value: isSwitched,
          onChanged: (value) {
            setState(() {
              isSwitched = value;
              print(isSwitched);
            });
          },
          activeTrackColor: Colors.lightBlueAccent,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  joinGroup() async {
    if (userNameController.text.length < 5) {
      Toast.show('Username must be 5 letters long.', context,
          duration: Toast.LENGTH_LONG, gravity: Toast.TOP);
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    UniversalData.username = userNameController.text;
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => MeetingScreen()));
  }
}
