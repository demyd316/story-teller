import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsFeedSettingsProvider with ChangeNotifier {
  NewsFeedSettingsProvider() {
    print('initialized NewsFeedSettingsProvider');
    _readAudioMuted().then((value) => isAudioMuted = value);
  }

  static const _isAudioMutedKey = 'isAudioMuted';

  bool _isAudioMuted = false;

  bool get isAudioMuted => _isAudioMuted;

  set isAudioMuted(bool value) {
    _isAudioMuted = value;
    _writeAudioMuted(value);
    notifyListeners();
  }

  Future<bool> _readAudioMuted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAudioMutedKey) ?? false;
  }

  Future<void> _writeAudioMuted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAudioMutedKey, value);
  }
}
