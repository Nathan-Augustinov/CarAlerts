import 'package:car_alerts/services/crash_reporting_service.dart';
import '../l10n/localized_content.dart';
import '../l10n/app_localizations.dart';
import '../widgets/calendar_day_refresh.dart';
import '../theme/app_theme.dart';
import '../services/notifications_service.dart';
import 'package:car_alerts/screens/add_or_edit_car_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';

enum _Filter { all, attention }

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen>
    with WidgetsBindingObserver, CalendarDayRefresh<CarsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  _Filter _filter = _Filter.all;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection('cars')
          .doc(currentUserId)
          .collection('user_cars');
  late final _carsStream = _collection.snapshots();

  Future<void> _edit([Car? car]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: const RouteSettings(name: 'car_editor'),
            builder: (_) => AddOrEditCarScreen(car: car)));
    if (mounted) setState(() {});
  }

  Future<void> _delete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeNamedCar(car.name)),
        content: Text(AppLocalizations.of(context)!
            .thisCarAndItsSavedExpiryDatesWillBeRemoved),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.keepCar)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.remove,
                  style: TextStyle(color: context.palette.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    CrashReportingService.instance.breadcrumb('car: delete_started');
    try {
      await _collection.doc(car.name).delete();
      CrashReportingService.instance.breadcrumb('car: delete_succeeded');
      await NotificationsService.instance.refresh();
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'delete_car');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.couldNotRemoveTheCarPleaseTryAgain),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _carsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              CrashReportingService.instance.report(
                  snapshot.error!, snapshot.stackTrace ?? StackTrace.current,
                  operation: 'cars_screen_load');
            }
            final cars = snapshot.data?.docs
                    .map((doc) => Car.fromMap(doc.data(), doc.id))
                    .toList() ??
                <Car>[];
            cars.sort((a, b) {
              final urgency = _priority(a).compareTo(_priority(b));
              return urgency == 0 ? a.name.compareTo(b.name) : urgency;
            });
            final attentionCount = cars.where(_needsAttention).length;
            final visible = cars
                .where((car) => _filter == _Filter.all || _needsAttention(car))
                .toList();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      sliver: SliverToBoxAdapter(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.yourGarage,
                              style: TextStyle(
                                  color: context.palette.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                          const SizedBox(height: 10),
                          Text(AppLocalizations.of(context)!.yourCars,
                              style: TextStyle(
                                  color: context.palette.ink,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1)),
                          const SizedBox(height: 6),
                          Text(
                              AppLocalizations.of(context)!
                                  .everyCarEveryDeadlineInOnePlace,
                              style: TextStyle(
                                  color: context.palette.muted, fontSize: 14)),
                          const SizedBox(height: 24),
                          if (snapshot.hasData && cars.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: context.palette.banner,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(children: [
                                Icon(Icons.shield_outlined,
                                    color: context.palette.bannerAccent,
                                    size: 30),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          attentionCount > 0
                                              ? AppLocalizations.of(context)!
                                                  .carsNeedAttention(
                                                      attentionCount)
                                              : AppLocalizations.of(context)!
                                                  .noUpcomingDeadlines,
                                          style: TextStyle(
                                              color: context.palette.onBanner,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17)),
                                      const SizedBox(height: 5),
                                      Text(
                                          AppLocalizations.of(context)!
                                              .expiredOrDueWithinTheNextDays,
                                          style: TextStyle(
                                              color:
                                                  context.palette.bannerMuted,
                                              fontSize: 12)),
                                    ])),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _filterChip(
                                  AppLocalizations.of(context)!
                                      .allCarsCount(cars.length),
                                  _Filter.all),
                              _filterChip(
                                  AppLocalizations.of(context)!
                                      .attentionCount(attentionCount),
                                  _Filter.attention),
                            ]),
                          ],
                        ],
                      )),
                    ),
                    if (snapshot.hasError)
                      SliverToBoxAdapter(
                          child: _EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: AppLocalizations.of(context)!
                                  .unableToLoadYourCars,
                              description: AppLocalizations.of(context)!
                                  .checkYourConnectionAndReopenThisPage))
                    else if (!snapshot.hasData)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.all(64),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: context.palette.accent))))
                    else if (visible.isEmpty)
                      SliverToBoxAdapter(
                          child: _EmptyState(
                        icon: cars.isEmpty
                            ? Icons.directions_car_outlined
                            : Icons.check_circle_outline,
                        title: cars.isEmpty
                            ? AppLocalizations.of(context)!.yourGarageStartsHere
                            : AppLocalizations.of(context)!
                                .nothingNeedsAttention,
                        description: cars.isEmpty
                            ? AppLocalizations.of(context)!
                                .addYourFirstCarToKeepInsuranceInspectionsAndVignettesTogether
                            : AppLocalizations.of(context)!
                                .noSavedDatesAreExpiredOrDueInTheNextDays,
                      ))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                          (context, index) => _CarCard(
                              car: visible[index],
                              onEdit: () => _edit(visible[index]),
                              onDelete: () => _delete(visible[index])),
                          childCount: visible.length,
                        )),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: context.palette.accent,
        foregroundColor: context.palette.onAccent,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addCar,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _filterChip(String label, _Filter filter) => ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        selectedColor: context.palette.selected,
        backgroundColor: context.palette.surface,
        labelStyle: TextStyle(
            color: _filter == filter
                ? context.palette.accent
                : context.palette.muted,
            fontWeight: FontWeight.w600),
        onSelected: (_) => setState(() => _filter = filter),
      );
}

int? _days(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return null;
  final now = DateTime.now();
  return DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
}

int _priority(Car car) {
  final days = car.allItems.values.map(_days).whereType<int>().toList()..sort();
  return days.isEmpty ? 999999 : days.first;
}

bool _needsAttention(Car car) => car.allItems.values.any((value) {
      final days = _days(value);
      return days != null && days <= 30;
    });

class _CarCard extends StatelessWidget {
  const _CarCard(
      {required this.car, required this.onEdit, required this.onDelete});
  final Car car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entries = car.allItems.entries.toList()
      ..sort((a, b) =>
          (_days(a.value) ?? 999999).compareTo(_days(b.value) ?? 999999));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.palette.background,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.directions_car_outlined,
                  color: context.palette.ink, size: 28)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(car.name,
                    style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context)!
                        .documentsTracked(entries.length),
                    style:
                        TextStyle(color: context.palette.muted, fontSize: 12)),
              ])),
        ]),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: context.palette.divider)),
        if (entries.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  AppLocalizations.of(context)!
                      .addExpiryDatesToStartTrackingThisCar,
                  style: TextStyle(color: context.palette.muted))),
        ...entries.map((entry) {
          final days = _days(entry.value);
          final color = days == null
              ? context.palette.muted
              : days < 0
                  ? context.palette.error
                  : days <= 30
                      ? context.palette.warning
                      : context.palette.accent;
          final status = days == null
              ? AppLocalizations.of(context)!.checkDate
              : days < 0
                  ? AppLocalizations.of(context)!.daysOverdue(days.abs())
                  : days == 0
                      ? AppLocalizations.of(context)!.dueToday
                      : days <= 30
                          ? AppLocalizations.of(context)!.dueInDays(days)
                          : AppLocalizations.of(context)!.upToDate;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: LayoutBuilder(builder: (context, constraints) {
              final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carItemLabel(context, car, entry.key),
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        days == null
                            ? AppLocalizations.of(context)!.updateThisExpiryDate
                            : localizedDate(context, entry.value),
                        style: TextStyle(
                            color: context.palette.muted, fontSize: 12)),
                  ]);
              final badge = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)));
              if (constraints.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 8), badge]);
              }
              return Row(children: [
                Expanded(child: title),
                const SizedBox(width: 8),
                badge
              ]);
            }),
          );
        }),
        Divider(height: 16, color: context.palette.divider),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          children: [
            TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(AppLocalizations.of(context)!.removeCar),
                style: TextButton.styleFrom(
                    foregroundColor: context.palette.error)),
            TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(AppLocalizations.of(context)!.manageCar),
                style: TextButton.styleFrom(
                    foregroundColor: context.palette.accent)),
          ],
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(children: [
          Icon(icon, size: 56, color: context.palette.accent),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(description,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, height: 1.5)),
        ]),
      );
}
