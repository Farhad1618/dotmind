import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ViewportVisibility extends ChangeNotifier {
  final List<ScrollableState> _scrollables = [];
  final List<ScrollPosition> _positions = [];
  BuildContext? _context;
  bool _visible = true;
  bool _scheduled = false;
  bool _disposed = false;

  bool get visible => _visible;

  void track(BuildContext context) {
    _context = context;
    _unlisten();
    _scrollables.clear();
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      _scrollables.add(scrollable);
      scrollable = scrollable.context.findAncestorStateOfType<ScrollableState>();
    }
    for (final scrollable in _scrollables) {
      final position = scrollable.position;
      position.addListener(_onScroll);
      _positions.add(position);
    }
    scheduleCheck(context);
  }

  void _onScroll() {
    final context = _context;
    if (context != null) scheduleCheck(context);
  }

  void scheduleCheck(BuildContext context) {
    _context = context;
    if (_disposed || _scheduled || _scrollables.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback(_afterFrame);
  }

  void _afterFrame(Duration _) {
    _scheduled = false;
    _check();
  }

  void _check() {
    if (_disposed) return;
    final next = _measure();
    if (next == _visible) return;
    _visible = next;
    notifyListeners();
  }

  bool _measure() {
    final context = _context;
    if (context == null || !context.mounted) return true;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return true;
    for (final scrollable in _scrollables) {
      if (!scrollable.mounted) continue;
      final viewport = scrollable.context.findRenderObject();
      if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) continue;
      final rect = MatrixUtils.transformRect(box.getTransformTo(viewport), Offset.zero & box.size);
      if (!rect.overlaps(Offset.zero & viewport.size)) return false;
    }
    return true;
  }

  void _unlisten() {
    for (final position in _positions) {
      position.removeListener(_onScroll);
    }
    _positions.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _unlisten();
    super.dispose();
  }
}
