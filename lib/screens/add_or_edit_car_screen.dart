import 'package:car_alerts/services/crash_reporting_service.dart';
import '../l10n/localized_content.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/expiry_validation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:car_alerts/main.dart';
import 'package:car_alerts/models/car.dart';
import 'package:car_alerts/services/notifications_service.dart';
import 'package:car_alerts/services/notification_permission_service.dart';
import '../services/car_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddOrEditCarScreen extends StatefulWidget {
  final Car? car;

  const AddOrEditCarScreen({super.key, this.car});

  @override
  State<AddOrEditCarScreen> createState() => _AddOrEditCarScreenState();
}

class _AddOrEditCarScreenState extends State<AddOrEditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _carNameController = TextEditingController();
  String carName = '';
  bool _saving = false;
  final Map<String, Map<String, String>> _customExpiries = {};
  bool isInsuranceSelected = false;
  bool isInspectionSelected = false;
  bool isRomanianVignetteSelected = false;
  bool isHungarianVignetteSelected = false;
  bool isAustrianVignetteSelected = false;

  DateTime? insuranceExpiringDate;
  DateTime? inspectionExpiringDate;
  DateTime? romanianVignetteExpiringDate;
  DateTime? hungarianVignetteExpiringDate;
  DateTime? austrianVignetteExpiringDate;

  String get errorText => AppLocalizations.of(context)!.error;
  String get successText => AppLocalizations.of(context)!.success;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.car != null) {
      _loadCarDetails();
    }
  }

  @override
  void dispose() {
    _carNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = [
          isInsuranceSelected,
          isInspectionSelected,
          isRomanianVignetteSelected,
          isHungarianVignetteSelected,
          isAustrianVignetteSelected
        ].where((value) => value).length +
        _customExpiries.length;
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        foregroundColor: context.palette.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.yourGarage,
            style: TextStyle(
                color: context.palette.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
      ),
      body: SafeArea(
          top: false,
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        widget.car == null
                            ? AppLocalizations.of(context)!.addACar
                            : AppLocalizations.of(context)!.editCar,
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    const SizedBox(height: 6),
                    Text(
                        widget.car == null
                            ? AppLocalizations.of(context)!
                                .aFewDetailsNowFewerSurprisesLater
                            : AppLocalizations.of(context)!
                                .keepYourCarSDetailsAndDeadlinesUpToDate,
                        style: TextStyle(
                            color: context.palette.muted, fontSize: 14)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: context.palette.banner,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        Icon(Icons.directions_car_outlined,
                            color: context.palette.bannerAccent, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(AppLocalizations.of(context)!.yourCarCovered,
                                  style: TextStyle(
                                      color: context.palette.onBanner,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(
                                  AppLocalizations.of(context)!
                                      .itemsTracked(selected),
                                  style: TextStyle(
                                      color: context.palette.bannerMuted,
                                      fontSize: 12,
                                      height: 1.5)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Text(AppLocalizations.of(context)!.carDetails,
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _cardDecoration,
                      child: TextFormField(
                        controller: _carNameController,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                            color: context.palette.ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1),
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.registrationNumber,
                          hintText: AppLocalizations.of(context)!.eGArXyz,
                          helperText: AppLocalizations.of(context)!
                              .useTheNumberOnYourLicencePlate,
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.directions_car_outlined),
                          filled: true,
                          fillColor: context.palette.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? AppLocalizations.of(context)!
                                    .enterYourRegistrationNumber
                                : value.contains('/')
                                    ? AppLocalizations.of(context)!
                                        .useARegistrationNumberWithoutSlashes
                                    : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(AppLocalizations.of(context)!.documentsExpiryDates,
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        AppLocalizations.of(context)!
                            .chooseWhatToTrackThenAddEachExpiryDate,
                        style: TextStyle(
                            color: context.palette.muted,
                            fontSize: 13,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    _document(
                        AppLocalizations.of(context)!.carInsurance,
                        AppLocalizations.of(context)!.insuranceCover,
                        Icons.shield_outlined,
                        isInsuranceSelected,
                        insuranceExpiringDate,
                        (value) => setState(() => isInsuranceSelected = value),
                        (date) => setState(() => insuranceExpiringDate = date)),
                    _document(
                        AppLocalizations.of(context)!.carInspection,
                        AppLocalizations.of(context)!.roadworthinessCheck,
                        Icons.build_outlined,
                        isInspectionSelected,
                        inspectionExpiringDate,
                        (value) => setState(() => isInspectionSelected = value),
                        (date) =>
                            setState(() => inspectionExpiringDate = date)),
                    Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text(AppLocalizations.of(context)!.roadVignettes,
                            style: TextStyle(
                                color: context.palette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5))),
                    _document(
                        AppLocalizations.of(context)!.romanianVignette,
                        AppLocalizations.of(context)!.romania,
                        Icons.confirmation_number_outlined,
                        isRomanianVignetteSelected,
                        romanianVignetteExpiringDate,
                        (value) =>
                            setState(() => isRomanianVignetteSelected = value),
                        (date) => setState(
                            () => romanianVignetteExpiringDate = date)),
                    _document(
                        AppLocalizations.of(context)!.hungarianVignette,
                        AppLocalizations.of(context)!.hungary,
                        Icons.confirmation_number_outlined,
                        isHungarianVignetteSelected,
                        hungarianVignetteExpiringDate,
                        (value) =>
                            setState(() => isHungarianVignetteSelected = value),
                        (date) => setState(
                            () => hungarianVignetteExpiringDate = date)),
                    _document(
                        AppLocalizations.of(context)!.austrianVignette,
                        AppLocalizations.of(context)!.austria,
                        Icons.confirmation_number_outlined,
                        isAustrianVignetteSelected,
                        austrianVignetteExpiringDate,
                        (value) =>
                            setState(() => isAustrianVignetteSelected = value),
                        (date) => setState(
                            () => austrianVignetteExpiringDate = date)),
                    const SizedBox(height: 28),
                    Text(AppLocalizations.of(context)!.otherExpiryDates,
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        AppLocalizations.of(context)!
                            .trackParkingPermitsWarrantiesAndMoreUpToPerCar,
                        style: TextStyle(
                            color: context.palette.muted, fontSize: 13)),
                    const SizedBox(height: 16),
                    for (final entry in _customExpiries.entries)
                      _customCard(entry.key, entry.value),
                    OutlinedButton.icon(
                      onPressed: _saving || _customExpiries.length >= 10
                          ? null
                          : () => setState(() {
                                final id = FirebaseFirestore.instance
                                    .collection('cars')
                                    .doc()
                                    .id;
                                _customExpiries[id] = {
                                  'name': '',
                                  'expiry_date': ''
                                };
                              }),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!
                          .addExpiryCount(_customExpiries.length)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        AppLocalizations.of(context)!
                            .youCanAddOrUpdateExpiryDatesAtAnyTime,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.palette.muted, fontSize: 12)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: context.palette.accent,
                          foregroundColor: context.palette.onAccent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: _saving ? null : _saveCar,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(
                          _saving
                              ? AppLocalizations.of(context)!.saving
                              : widget.car == null
                                  ? AppLocalizations.of(context)!.saveCar
                                  : AppLocalizations.of(context)!.saveChanges,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ))),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.palette.border));

  Widget _document(
      String title,
      String subtitle,
      IconData icon,
      bool selected,
      DateTime? date,
      ValueChanged<bool> onChanged,
      ValueChanged<DateTime> onDateSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.palette.border),
        ),
        child: Column(children: [
          SwitchListTile.adaptive(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            activeTrackColor: context.palette.accent,
            secondary: Icon(icon,
                color:
                    selected ? context.palette.accent : context.palette.muted),
            title: Text(title,
                style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle,
                style: TextStyle(color: context.palette.muted, fontSize: 12)),
            value: selected,
            onChanged: _saving ? null : onChanged,
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: FormField<DateTime>(
                key: ValueKey('$title-$date'),
                initialValue: date,
                validator: (_) => validateExpiryDate(date,
                    localizations: AppLocalizations.of(context),
                    original: _originalDate(title)),
                builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: context.palette.background,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _saving
                              ? null
                              : () async {
                                  final now = DateTime.now();
                                  final today =
                                      DateTime(now.year, now.month, now.day);
                                  final initial =
                                      date == null || date.isBefore(today)
                                          ? today
                                          : date;
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial,
                                    firstDate: today,
                                    lastDate: DateTime(
                                        initial.year > now.year + 15
                                            ? initial.year
                                            : now.year + 15,
                                        12,
                                        31),
                                    helpText: AppLocalizations.of(context)!
                                        .documentExpiry(title),
                                  );
                                  if (picked != null && mounted) {
                                    onDateSelected(picked);
                                  }
                                },
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: context.palette.accent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .expiryDate,
                                          style: TextStyle(
                                              color: context.palette.muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text(
                                          date == null
                                              ? AppLocalizations.of(context)!
                                                  .chooseADate
                                              : localizedDate(context,
                                                  date.toIso8601String()),
                                          style: TextStyle(
                                              color: context.palette.ink,
                                              fontWeight: FontWeight.w600)),
                                    ])),
                                Icon(Icons.chevron_right,
                                    color: context.palette.muted, size: 20),
                              ])),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(field.errorText!,
                                style: TextStyle(
                                    color: context.palette.error,
                                    fontSize: 12))),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }

  String? _originalDate(String title) {
    final keys = {
      AppLocalizations.of(context)!.carInsurance: 'insurance_date',
      AppLocalizations.of(context)!.carInspection: 'inspection_date',
      AppLocalizations.of(context)!.romanianVignette: 'romanian_vignette_date',
      AppLocalizations.of(context)!.hungarianVignette:
          'hungarian_vignette_date',
      AppLocalizations.of(context)!.austrianVignette: 'austrian_vignette_date',
    };
    return widget.car?.items[keys[title]];
  }

  Widget _customCard(String id, Map<String, String> item) {
    final date = DateTime.tryParse(item['expiry_date'] ?? '');
    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: TextFormField(
            initialValue: item['name'],
            enabled: !_saving,
            maxLength: 50,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.expiryName,
                hintText: AppLocalizations.of(context)!.eGParkingPermit),
            onChanged: (value) => item['name'] = value,
            validator: (value) {
              final name = (value ?? '').trim();
              if (name.isEmpty) {
                return AppLocalizations.of(context)!.enterAnExpiryName;
              }
              if (name.length > 50) {
                return AppLocalizations.of(context)!.useCharactersOrFewer;
              }
              if (_customExpiries.entries.any((other) =>
                  other.key != id &&
                  other.value['name']!.trim().toLowerCase() ==
                      name.toLowerCase())) {
                return AppLocalizations.of(context)!.useADifferentExpiryName;
              }
              return null;
            },
          )),
          IconButton(
              tooltip: AppLocalizations.of(context)!.removeExpiry,
              onPressed: _saving
                  ? null
                  : () => setState(() => _customExpiries.remove(id)),
              icon: const Icon(Icons.delete_outline)),
        ]),
        FormField<DateTime>(
          key: ValueKey('$id-$date'),
          validator: (_) => validateExpiryDate(date,
              localizations: AppLocalizations.of(context),
              original: widget.car?.customExpiries[id]?['expiry_date']),
          builder: (field) =>
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final initial =
                          date == null || date.isBefore(today) ? today : date;
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: today,
                          lastDate: DateTime(
                              initial.year > now.year + 15
                                  ? initial.year
                                  : now.year + 15,
                              12,
                              31),
                          helpText:
                              AppLocalizations.of(context)!.expiryDateText);
                      if (picked != null && mounted) {
                        setState(() =>
                            item['expiry_date'] = picked.toIso8601String());
                      }
                    },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(date == null
                  ? AppLocalizations.of(context)!.chooseExpiryDate
                  : localizedDate(context, item['expiry_date']!)),
            ),
            if (field.hasError)
              Text(field.errorText!,
                  style: TextStyle(color: context.palette.error, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Future<void> _saveCar() async {
    if (_saving) return;
    if (_formKey.currentState!.validate()) {
      carName = _carNameController.text.trim();

      if (carName.isEmpty) {
        _showErrorPopUp(
            AppLocalizations.of(context)!.pleaseEnterTheRegistrationNumber,
            errorText);
        return;
      }

      if (isInsuranceSelected && insuranceExpiringDate == null) {
        _showErrorPopUp(
            AppLocalizations.of(context)!
                .pleaseSelectTheInsuranceExpirationDate,
            errorText);
        return;
      }
      if (isInspectionSelected && inspectionExpiringDate == null) {
        _showErrorPopUp(
            AppLocalizations.of(context)!
                .pleaseSelectTheInspectionExpirationDate,
            errorText);
        return;
      }
      if (isRomanianVignetteSelected && romanianVignetteExpiringDate == null) {
        _showErrorPopUp(
            AppLocalizations.of(context)!
                .pleaseSelectTheRomanianVignetteExpirationDate,
            errorText);
        return;
      }
      if (isHungarianVignetteSelected &&
          hungarianVignetteExpiringDate == null) {
        _showErrorPopUp(
            AppLocalizations.of(context)!
                .pleaseSelectTheHungarianVignetteExpirationDate,
            errorText);
        return;
      }
      if (isAustrianVignetteSelected && austrianVignetteExpiringDate == null) {
        _showErrorPopUp(
            AppLocalizations.of(context)!
                .pleaseSelectTheAustrianVignetteExpirationDate,
            errorText);
        return;
      }
      setState(() => _saving = true);
      try {
        await _addCarToDatabase();
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _addCarToDatabase() async {
    Map<String, dynamic> carData = {
      'custom_expiries': {
        for (final entry in _customExpiries.entries)
          entry.key: {...entry.value, 'name': entry.value['name']!.trim()}
      },
      'insurance_date':
          isInsuranceSelected ? insuranceExpiringDate?.toIso8601String() : null,
      'inspection_date': isInspectionSelected
          ? inspectionExpiringDate?.toIso8601String()
          : null,
      'romanian_vignette_date': isRomanianVignetteSelected
          ? romanianVignetteExpiringDate?.toIso8601String()
          : null,
      'hungarian_vignette_date': isHungarianVignetteSelected
          ? hungarianVignetteExpiringDate?.toIso8601String()
          : null,
      'austrian_vignette_date': isAustrianVignetteSelected
          ? austrianVignetteExpiringDate?.toIso8601String()
          : null,
    };

    CrashReportingService.instance.breadcrumb('car: save_started');
    try {
      carData = await CarService().save(
        userId: currentUserId,
        registration: carName,
        previousRegistration: widget.car?.name,
        originalDates: widget.car == null
            ? null
            : {
                for (final key
                    in carData.keys.where((key) => key != 'custom_expiries'))
                  key: DateTime.tryParse(widget.car!.items[key] ?? '')
                          ?.toIso8601String() ??
                      widget.car!.items[key],
                'custom_expiries': widget.car!.customExpiries,
              },
        dates: carData,
      );
    } on CarSaveException catch (error) {
      if (mounted) _showErrorPopUp(error.message, errorText);
      return;
    } on FirebaseException catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'save_car');
      debugPrint(
          'Car save failed [${error.plugin}/${error.code}]: ${error.message}');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        _showErrorPopUp(
            AppLocalizations.of(context)!.couldNotSaveYourCarPleaseTryAgain,
            errorText);
      }
      return;
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'save_car');
      debugPrint('Car save failed: $error');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        _showErrorPopUp(
            AppLocalizations.of(context)!.couldNotSaveYourCarPleaseTryAgain,
            errorText);
      }
      return;
    }
    CrashReportingService.instance.breadcrumb('car: save_succeeded');
    String? reminderWarning;
    bool notificationsOff = false;
    try {
      if (Car.fromMap(carData, carName).allItems.isNotEmpty) {
        await NotificationPermissionService().requestIfNotAsked();
      }
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'request_notification_permission');
      // Permission errors must not prevent reconciliation or undo the save.
    }
    final result = await NotificationsService.instance.refresh(
        savedUser: currentUserId,
        savedCar: carName,
        renamedFrom: widget.car?.name,
        savedDates: carData);
    if (!mounted) return;
    notificationsOff = result == ReminderStatus.disabled;
    if (result == ReminderStatus.failed) {
      reminderWarning =
          AppLocalizations.of(context)!.carSavedRemindersWillRetryAutomatically;
    } else if (notificationsOff) {
      reminderWarning =
          AppLocalizations.of(context)!.carSavedNotificationsAreDisabled;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    mainScreenKey.currentState?.selectTab(1);
    messenger.showSnackBar(SnackBar(
      content: Text(reminderWarning ?? AppLocalizations.of(context)!.carSaved),
      action: notificationsOff
          ? SnackBarAction(
              label: AppLocalizations.of(context)!.settings,
              onPressed: () async {
                try {
                  await NotificationPermissionService().openSettings();
                } catch (error, stack) {
                  CrashReportingService.instance.report(error, stack,
                      operation: 'open_notification_settings');
                  if (messenger.mounted) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .couldNotOpenSettings)));
                  }
                }
              })
          : null,
    ));
  }

  void _showErrorPopUp(String errorMessage, String titleMesssage) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(titleMesssage),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (titleMesssage == successText) {
                      Navigator.of(context).pop();
                      mainScreenKey.currentState?.selectTab(1);
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.ok))
            ],
          );
        });
  }

  void _loadCarDetails() {
    _customExpiries.addAll({
      for (final entry in widget.car!.customExpiries.entries)
        entry.key: Map<String, String>.from(entry.value)
    });
    carName = _carNameController.text = widget.car!.name;
    isInsuranceSelected = widget.car!.items['insurance_date'] != null;
    isInspectionSelected = widget.car!.items['inspection_date'] != null;
    isRomanianVignetteSelected =
        widget.car!.items['romanian_vignette_date'] != null;
    isHungarianVignetteSelected =
        widget.car!.items['hungarian_vignette_date'] != null;
    isAustrianVignetteSelected =
        widget.car!.items['austrian_vignette_date'] != null;

    insuranceExpiringDate = widget.car!.items['insurance_date'] != null
        ? DateTime.tryParse(widget.car!.items['insurance_date']!)
        : null;
    inspectionExpiringDate = widget.car!.items['inspection_date'] != null
        ? DateTime.tryParse(widget.car!.items['inspection_date']!)
        : null;
    romanianVignetteExpiringDate =
        widget.car!.items['romanian_vignette_date'] != null
            ? DateTime.tryParse(widget.car!.items['romanian_vignette_date']!)
            : null;
    hungarianVignetteExpiringDate =
        widget.car!.items['hungarian_vignette_date'] != null
            ? DateTime.tryParse(widget.car!.items['hungarian_vignette_date']!)
            : null;
    austrianVignetteExpiringDate =
        widget.car!.items['austrian_vignette_date'] != null
            ? DateTime.tryParse(widget.car!.items['austrian_vignette_date']!)
            : null;
  }
}
