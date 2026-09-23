import '../theme/app_theme.dart';
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

  final String errorText = "Error";
  final String successText = "Success";
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
    ].where((value) => value).length;
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        foregroundColor: context.palette.ink,
        surfaceTintColor: Colors.transparent,
        title: Text('YOUR GARAGE',
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
                    Text(widget.car == null ? 'Add a car' : 'Edit car',
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    const SizedBox(height: 6),
                    Text(
                        widget.car == null
                            ? 'A few details now. Fewer surprises later.'
                            : 'Keep your car’s details and deadlines up to date.',
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
                              Text('Your car, covered',
                                  style: TextStyle(
                                      color: context.palette.onBanner,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(
                                  '$selected ${selected == 1 ? 'document selected' : 'documents selected'} for expiry tracking',
                                  style: TextStyle(
                                      color: context.palette.bannerMuted,
                                      fontSize: 12,
                                      height: 1.5)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Text('Car details',
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
                          labelText: 'Registration number',
                          hintText: 'e.g. AR00XYZ',
                          helperText: 'Use the number on your licence plate.',
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.directions_car_outlined),
                          filled: true,
                          fillColor: context.palette.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? 'Enter your registration number.'
                            : value.contains('/')
                                ? 'Use a registration number without slashes.'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Documents & expiry dates',
                        style: TextStyle(
                            color: context.palette.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Choose what to track, then add each expiry date.',
                        style: TextStyle(
                            color: context.palette.muted,
                            fontSize: 13,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    _document(
                        'Car insurance',
                        'Insurance cover',
                        Icons.shield_outlined,
                        isInsuranceSelected,
                        insuranceExpiringDate,
                        (value) => setState(() => isInsuranceSelected = value),
                        (date) => setState(() => insuranceExpiringDate = date)),
                    _document(
                        'Car inspection',
                        'Roadworthiness check',
                        Icons.build_outlined,
                        isInspectionSelected,
                        inspectionExpiringDate,
                        (value) => setState(() => isInspectionSelected = value),
                        (date) =>
                            setState(() => inspectionExpiringDate = date)),
                    Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Text('ROAD VIGNETTES',
                            style: TextStyle(
                                color: context.palette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5))),
                    _document(
                        'Romanian vignette',
                        'Romania',
                        Icons.confirmation_number_outlined,
                        isRomanianVignetteSelected,
                        romanianVignetteExpiringDate,
                        (value) =>
                            setState(() => isRomanianVignetteSelected = value),
                        (date) => setState(
                            () => romanianVignetteExpiringDate = date)),
                    _document(
                        'Hungarian vignette',
                        'Hungary',
                        Icons.confirmation_number_outlined,
                        isHungarianVignetteSelected,
                        hungarianVignetteExpiringDate,
                        (value) =>
                            setState(() => isHungarianVignetteSelected = value),
                        (date) => setState(
                            () => hungarianVignetteExpiringDate = date)),
                    _document(
                        'Austrian vignette',
                        'Austria',
                        Icons.confirmation_number_outlined,
                        isAustrianVignetteSelected,
                        austrianVignetteExpiringDate,
                        (value) =>
                            setState(() => isAustrianVignetteSelected = value),
                        (date) => setState(
                            () => austrianVignetteExpiringDate = date)),
                    const SizedBox(height: 12),
                    Text('You can add or update documents at any time.',
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
                              ? 'Saving…'
                              : widget.car == null
                                  ? 'Save car'
                                  : 'Save changes',
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
                validator: (_) =>
                    date == null ? 'Choose an expiry date.' : null,
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
                                  final initial = date ?? now;
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial,
                                    firstDate: DateTime(initial.year < 2021
                                        ? initial.year
                                        : 2021),
                                    lastDate: DateTime(
                                        initial.year > now.year + 15
                                            ? initial.year
                                            : now.year + 15,
                                        12,
                                        31),
                                    helpText: '$title expiry',
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
                                      Text('EXPIRY DATE',
                                          style: TextStyle(
                                              color: context.palette.muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text(
                                          date == null
                                              ? 'Choose a date'
                                              : Car.extractDate(
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

  Future<void> _saveCar() async {
    if (_saving) return;
    if (_formKey.currentState!.validate()) {
      carName = _carNameController.text.trim();

      if (carName.isEmpty) {
        _showErrorPopUp("Please enter the registration number!", errorText);
        return;
      }

      if (isInsuranceSelected && insuranceExpiringDate == null) {
        _showErrorPopUp(
            "Please select the insurance expiration date!", errorText);
        return;
      }
      if (isInspectionSelected && inspectionExpiringDate == null) {
        _showErrorPopUp(
            "Please select the inspection expiration date!", errorText);
        return;
      }
      if (isRomanianVignetteSelected && romanianVignetteExpiringDate == null) {
        _showErrorPopUp(
            "Please select the romanian vignette expiration date!", errorText);
        return;
      }
      if (isHungarianVignetteSelected &&
          hungarianVignetteExpiringDate == null) {
        _showErrorPopUp(
            "Please select the hungarian vignette expiration date!", errorText);
        return;
      }
      if (isAustrianVignetteSelected && austrianVignetteExpiringDate == null) {
        _showErrorPopUp(
            "Please select the austrian vignette expiration date!", errorText);
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

    try {
      await CarService().save(
        userId: currentUserId,
        registration: carName,
        previousRegistration: widget.car?.name,
        dates: carData,
      );
    } on CarSaveException catch (error) {
      if (mounted) _showErrorPopUp(error.message, errorText);
      return;
    } catch (_) {
      if (mounted) {
        _showErrorPopUp(
            'Could not save your car. Please try again.', errorText);
      }
      return;
    }
    String? reminderWarning;
    bool notificationsOff = false;
    try {
      if (carData.values.any((value) => value != null)) {
        await NotificationPermissionService().requestIfNotAsked();
      }
    } catch (_) {
      // Permission errors must not prevent reconciliation or undo the save.
    }
    final result = await NotificationsService.instance.refresh(
        savedUser: currentUserId,
        savedCar: carName,
        renamedFrom: widget.car?.name,
        savedDates: carData);
    notificationsOff = result == ReminderStatus.disabled;
    if (result == ReminderStatus.failed) {
      reminderWarning = 'Car saved. Reminders will retry automatically.';
    } else if (notificationsOff) {
      reminderWarning = 'Car saved. Notifications are disabled.';
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    mainScreenKey.currentState?.selectTab(1);
    messenger.showSnackBar(SnackBar(
      content: Text(reminderWarning ?? 'Car saved.'),
      action: notificationsOff
          ? SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                try {
                  await NotificationPermissionService().openSettings();
                } catch (_) {
                  if (messenger.mounted) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Could not open Settings.')));
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
                  child: const Text('OK'))
            ],
          );
        });
  }

  void _loadCarDetails() {
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
