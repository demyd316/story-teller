import 'package:flutter/material.dart';
import 'src/app.dart';
import 'dart:io';
import 'src/constant/utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  //Admob.initialize(getAppId());
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('fr', timeago.ItMessages());
  timeago.setLocaleMessages('it', timeago.ItMessages());
  timeago.setLocaleMessages('zh', timeago.ZhMessages());
  timeago.setLocaleMessages('ru', timeago.RuMessages());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

String getAppId() {
  if (Platform.isIOS) {
    return NetworkUtils.ADMOB_APP_ID_IOS;
  } else if (Platform.isAndroid) {
    return NetworkUtils.ADMOB_APP_ID_ANDROID;
  }
  return null;
}
