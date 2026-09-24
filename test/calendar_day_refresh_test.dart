import 'package:car_alerts/widgets/calendar_day_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class CalendarProbe extends StatefulWidget {
  const CalendarProbe(this.now, {super.key});
  final DateTime Function() now;
  @override
  State<CalendarProbe> createState() => _CalendarProbeState();
}

class _CalendarProbeState extends State<CalendarProbe>
    with WidgetsBindingObserver, CalendarDayRefresh<CalendarProbe> {
  @override
  DateTime calendarNow() => widget.now();
  @override
  Widget build(BuildContext context) =>
      Text('${calendarNow().day}', textDirection: TextDirection.ltr);
}

void main() {
  testWidgets('updates at midnight, on resume, and cancels on disposal',
      (tester) async {
    var now = DateTime(2030, 7, 1, 23, 59, 59);
    await tester.pumpWidget(CalendarProbe(() => now));
    expect(find.text('1'), findsOneWidget);
    now = DateTime(2030, 7, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2030, 7, 5, 12);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(days: 2));
    expect(tester.takeException(), isNull);
  });
}
