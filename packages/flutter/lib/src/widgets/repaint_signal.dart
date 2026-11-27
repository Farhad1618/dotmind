import 'package:flutter/foundation.dart';

class RepaintSignal extends ChangeNotifier {
  void ping() => notifyListeners();
}
