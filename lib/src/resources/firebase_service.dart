import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../ui/globals.dart' as global;
import 'package:flutter_flexible_toast/flutter_flexible_toast.dart';

class FirebaseService {
  bool userLogged = false;

  int userID;
  String deviceID = '';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void initService(int uid) {
    configureFirebaseMessaging(uid);
  }

  void removeService() async {
    // remove collection document in DB
    userLogged = false;
  }

  void checkIfTokenExist(int uid) async {
    print('check previous token');

    bool exist = false;
    try {
      // ignore: deprecated_member_use
      await _db
          .collection('users')
          .document('$uid')
          .collection('tokens')
          .getDocuments()
          .then((doc) {
        if (doc.documents.length > 0)
          _db
              .collection('users')
              .document('$uid')
              .collection('tokens')
              .getDocuments()
              .then((subdoc) {
            for (DocumentSnapshot ds in subdoc.documents) ds.reference.delete();
          });
        else
          exist = false;
      });
      print('deleted!');
    } catch (e) {
      print('false check previous token');
    }
  }

  _saveDeviceToken(int uid) async {
    //checkIfTokenExist(uid);

    if (uid != null) {
      userID = uid;
      String fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        // ignore: deprecated_member_use
        var tokens = _db
            .collection('users')
            .document('$uid')
            .collection('tokens')
            .document(fcmToken);
        // ignore: deprecated_member_use
        await tokens.setData({
          'token': fcmToken,
          'createdAt': FieldValue.serverTimestamp(), // optional
          'platform': Platform.operatingSystem // optional
        });
        userLogged = true;
      }
    }
  }

  void saveUserFollowFirestore(int ownerid) async {
    if (ownerid != global.userId) {
      // ignore: deprecated_member_use
      var tks =
          // ignore: deprecated_member_use
          _db
              .collection('follow_notify')
              .document('$ownerid' + '_' + '${global.userId}');

      //int tempId = 49;
      await tks.setData({
        'toId': ownerid,
        'fromId': global.userId,
        'avartar': global.avatar,
        'name': global.name,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem // optional
      });
    } else {
      print('Err follow notify ~~~~~~');
    }
  }

  void saveUserPostLikeFirestore(int ownerid) async {
    if (ownerid != global.userId) {
      // ignore: deprecated_member_use
      var tks = _db
          .collection('postlike_notify')
          .document('$ownerid' + '_' + '${global.userId}');
      await tks.setData({
        'toId': ownerid,
        'fromId': global.userId,
        'avartar': global.avatar,
        'name': global.name,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem // optional
      });
      
    } else {
      print('Err post like notify ~~~~~~');
    }
  }

  void saveUserGetMessageFirestore(int ownerid) async {
    if (ownerid != global.userId) {
      // ignore: deprecated_member_use
      var tks =
          // ignore: deprecated_member_use
          _db
              .collection('message_notify')
              .document('$ownerid' + '_' + '${global.userId}');
      await tks.setData({
        'toId': ownerid,
        'fromId': global.userId,
        'avartar': global.avatar,
        'name': global.name,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem // optional
      });
    } else {
      print('Err post like notify ~~~~~~');
    }
  }

  void configureFirebaseMessaging(uid) {
    // ignore: missing_return
    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('on resume $message');
      showNofication(message);
      // ignore: missing_return
    }, onResume: (Map<String, dynamic> message) {
      print('on resume $message');
      // ignore: missing_return
    }, onLaunch: (Map<String, dynamic> message) {
      print('on resume $message');
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    if (uid != null) {
      _saveDeviceToken(uid);
    }
  }

  void showNofication(Map<String, dynamic> token) {
/*     Fluttertoast.showToast(
      msg: token['notification']['body'],
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 14.0,
    ); */

    FlutterFlexibleToast.showToast(
        message: token['notification']['body'],
        toastLength: Toast.LENGTH_LONG,
        toastGravity: ToastGravity.BOTTOM,
        icon: ICON.INFO,
        radius: 0,
        elevation: 10,
        imageSize: 12,
        textColor: Colors.white,
        backgroundColor: Colors.grey.shade700,
        timeInSeconds: 2,
        fontSize: 16.0);
  }
}
