import 'dart:async';
import 'dart:html' as html;

Future<bool> requestCameraPermission() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      return false;
    }
    await mediaDevices.getUserMedia({'video': true});
    return true;
  } catch (_) {
    return false;
  }
}
