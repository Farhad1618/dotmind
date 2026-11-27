import 'package:flutter/foundation.dart';

abstract interface class ShimmerDriver {
  Listenable get tick;

  double get elapsed;
}
