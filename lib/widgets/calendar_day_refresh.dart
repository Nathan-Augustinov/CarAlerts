import 'dart:async';
import 'package:flutter/widgets.dart';

/// Keeps date-dependent UI current across midnight and backgrounding.
mixin CalendarDayRefresh<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Timer? _midnight;

  DateTime calendarNow() => DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = calendarNow();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), _refreshCalendar);
  }

  void _refreshCalendar() {
    if (!mounted) return;
    setState(() {});
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCalendar();
    } else {
      _midnight?.cancel();
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
