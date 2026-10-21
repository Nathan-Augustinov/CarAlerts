import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_content.dart';
import '../models/car.dart';
import '../services/local_car_store.dart';
import '../services/local_car_transfer.dart';
import '../services/notifications_service.dart';

/// A route-level decision survives dialog dismissal and is recreated on launch
/// whenever an authenticated account and a local record coexist.
class LocalTransferScreen extends StatefulWidget {
  const LocalTransferScreen(
      {super.key, required this.account, this.transfer, this.refreshReminders});
  final LocalCarTransfer? transfer;
  final Future<void> Function()? refreshReminders;
  final String account;
  @override
  State<LocalTransferScreen> createState() => _LocalTransferScreenState();
}

class _LocalTransferScreenState extends State<LocalTransferScreen> {
  late final transfer = widget.transfer ??
      LocalCarTransfer(
          local: LocalCarStore.instance,
          firestore: FirebaseFirestore.instance,
          currentUser: () => FirebaseAuth.instance.currentUser?.uid);
  bool saving = false,
      failed = false,
      confirmingDelete = false,
      conflict = false;
  Map<String, dynamic>? accountDates;
  bool retryKeepAccount = false;

  Future<void> move({bool keepAccount = false}) async {
    if (saving) return;
    retryKeepAccount = keepAccount;
    setState(() {
      saving = true;
      failed = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    try {
      final result = await transfer.move(widget.account,
          expected: accountDates, keepAccount: keepAccount);
      if (result != TransferResult.alreadyPresent) {
        messenger.showSnackBar(SnackBar(content: Text(l.localTransferSuccess)));
      }
      await (widget.refreshReminders?.call() ??
          NotificationsService.instance.refresh());
    } on TransferConflict catch (e) {
      if (mounted) {
        setState(() {
          accountDates = e.dates;
          conflict = e.dates != null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> delete() async {
    if (saving) return;
    setState(() {
      saving = true;
      failed = false;
    });
    try {
      if (transfer.currentUser() != widget.account) return;
      await transfer.local.delete(expectedToken: transfer.local.token);
      await (widget.refreshReminders?.call() ??
          NotificationsService.instance.refresh());
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget dates(String title, Map<String, dynamic> data) {
    final car = Car.fromMap(data, transfer.local.registration ?? '');
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                for (final entry in car.allItems.entries)
                  Text(
                      '${entry.key.startsWith('custom:') ? car.itemLabel(entry.key) : documentLabel(AppLocalizations.of(context)!, entry.key)}: ${localizedDate(context, entry.value)}'),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = transfer.local.registration ?? '';
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: SafeArea(
                child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                      confirmingDelete
                          ? l.localDeleteTitle
                          : conflict
                              ? l.localDuplicateTitle
                              : l.localTransferTitle,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Text(confirmingDelete
                      ? l.localDeleteBody(name)
                      : conflict
                          ? l.localDuplicateBody(name)
                          : l.localTransferBody(name)),
                  if (conflict && !confirmingDelete) ...[
                    dates(l.localDeviceDates, transfer.local.dates ?? {}),
                    dates(l.localAccountDates, accountDates!),
                  ],
                  if (saving) ...[
                    const LinearProgressIndicator(),
                    Text(l.localTransferSaving)
                  ],
                  if (failed)
                    Text(l.localTransferFailure,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: saving
                          ? null
                          : confirmingDelete
                              ? delete
                              : () =>
                                  move(keepAccount: failed && retryKeepAccount),
                      child: Text(confirmingDelete
                          ? l.localDeleteContinue
                          : failed
                              ? l.localTryAgain
                              : conflict
                                  ? l.localUseDevice
                                  : l.localTransferMove)),
                  TextButton(
                      onPressed: saving
                          ? null
                          : () {
                              if (confirmingDelete) {
                                setState(() {
                                  confirmingDelete = false;
                                  failed = false;
                                });
                              } else if (conflict) {
                                move(keepAccount: true);
                              } else {
                                setState(() => confirmingDelete = true);
                              }
                            },
                      child: Text(confirmingDelete
                          ? l.localGoBack
                          : conflict
                              ? l.localKeepAccount
                              : l.localTransferDelete)),
                ]),
          ),
        ))));
  }
}
