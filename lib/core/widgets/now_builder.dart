import 'dart:async';

import 'package:flutter/material.dart';

/// Rebuilds its child every [every] with the CURRENT time, so statuses that
/// depend on the clock (upcoming -> due -> unconfirmed) change on screen at the
/// exact moment instead of waiting for some unrelated rebuild.
class NowBuilder extends StatefulWidget {
  const NowBuilder({super.key, required this.builder, this.every = const Duration(seconds: 5)});
  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration every;

  @override
  State<NowBuilder> createState() => _NowBuilderState();
}

class _NowBuilderState extends State<NowBuilder> with WidgetsBindingObserver {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(widget.every, (_) => _tick());
  }

  void _tick() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick(); // fresh status right after returning
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
