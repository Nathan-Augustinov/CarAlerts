import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import '../services/crash_reporting_service.dart';

/// Compiled out of release UI; only enabled with ENABLE_CRASHLYTICS=true.
class CrashlyticsTestControls extends StatelessWidget {
  const CrashlyticsTestControls({super.key});
  @override
  Widget build(BuildContext context) {
    if (!CrashReportingService.testControls) return const SizedBox.shrink();
    return Column(children: [
      const Text('Crashlytics development tests'),
      TextButton(
          onPressed: () async {
            await CrashReportingService.instance
                .breadcrumb('test: handled_error');
            try {
              throw StateError('Crashlytics test');
            } catch (error, stack) {
              await CrashReportingService.instance
                  .report(error, stack, operation: 'test_handled_error');
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Test error recorded. Restart this test build to upload.')));
            }
          },
          child: const Text('Record test error')),
      TextButton(
          onPressed: () async {
            await CrashReportingService.instance
                .breadcrumb('test: uncaught_error');
            throw StateError('Crashlytics uncaught test');
          },
          child: const Text('Trigger uncaught test error')),
      TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('Crash the app for testing?'),
                      content: const Text(
                          'The app will close. Reopen this test build to upload the report.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Crash app')),
                      ],
                    ));
            if (confirmed == true) {
              await CrashReportingService.instance
                  .breadcrumb('test: native_crash');
              FirebaseCrashlytics.instance.crash();
            }
          },
          child: const Text('Trigger native test crash')),
    ]);
  }
}
