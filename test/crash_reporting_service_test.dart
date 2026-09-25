import 'package:car_alerts/services/crash_reporting_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MemorySink implements CrashSink {
  final events = <String>[];
  final reports = <String>[];
  final stacks = <StackTrace>[];
  String uid = '';
  bool fail = false;
  @override
  Future<void> collection(bool enabled) async =>
      events.add('collection:$enabled');
  @override
  Future<void> discard() async => events.add('discard');
  @override
  Future<void> user(String id) async {
    uid = id;
    events.add('user:$id');
  }

  @override
  Future<void> key(String name, String value) async =>
      events.add('$name:$value');
  @override
  Future<void> log(String message) async {
    if (fail) throw StateError('SDK unavailable');
    events.add(message);
  }

  @override
  Future<void> error(String description, StackTrace stack, String operation,
      bool fatal) async {
    reports.add('$uid|$description|$operation|$fatal');
    stacks.add(stack);
  }
}

void main() {
  test('normal debug mode disables uploads and drops pending test reports',
      () async {
    final sink = MemorySink();
    final service = CrashReportingService(sink: sink);
    await service.initialize();
    await service.setUser('uid');
    await service.breadcrumb('save');
    await service.report(StateError('private'), StackTrace.current,
        operation: 'save');
    expect(sink.events, ['collection:false', 'discard']);
    expect(sink.reports, isEmpty);
  });

  test(
      'UID changes and reports stay ordered; stack survives without private message',
      () async {
    final sink = MemorySink();
    final service = CrashReportingService(sink: sink);
    await service.initialize(enabled: true);
    service.setUser('first');
    service.screen('car_editor');
    final stack = StackTrace.fromString('originalFunction (car.dart:10:2)');
    service.report(
        PlatformException(code: 'failed', message: 'email@example.com ABC123'),
        stack,
        operation: 'save_car');
    service.setUser(null);
    await service.report(StateError('secret'), stack, operation: 'load');
    expect(sink.reports.first, startsWith('first|PlatformException [failed]'));
    expect(sink.reports.last, startsWith('|StateError'));
    expect(sink.reports.join(), isNot(contains('email@example.com')));
    expect(sink.stacks, [stack, stack]);
    expect(sink.events, contains('environment:development_test'));
  });

  test(
      'expected errors excluded; repeated errors limited but fatal errors retained',
      () async {
    var now = DateTime(2030);
    final sink = MemorySink();
    final service = CrashReportingService(sink: sink, now: () => now);
    await service.initialize(enabled: true);
    final stack = StackTrace.current;
    await service.report(FirebaseAuthException(code: 'wrong-password'), stack,
        operation: 'auth');
    expect(sink.reports, isEmpty);
    for (var i = 0; i < 3; i++) {
      await service.report(StateError('fail'), stack, operation: 'retry');
    }
    expect(sink.reports, hasLength(1));
    await service.report(StateError('fail'), stack,
        operation: 'retry', fatal: true);
    expect(sink.reports, hasLength(2));
    now = now.add(const Duration(minutes: 1));
    await service.report(StateError('fail'), stack, operation: 'retry');
    expect(sink.reports, hasLength(3));
  });

  test('reporting SDK failures do not break operations or subsequent reports',
      () async {
    final sink = MemorySink();
    final service = CrashReportingService(sink: sink);
    await service.initialize(enabled: true);
    sink.fail = true;
    await service.breadcrumb('test');
    sink.fail = false;
    await service.report(StateError('test'), StackTrace.current,
        operation: 'test');
    expect(sink.reports, hasLength(1));
  });
}
