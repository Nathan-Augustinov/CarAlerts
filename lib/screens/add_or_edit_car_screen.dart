import 'dart:async';
import 'package:car_alerts/main.dart';
import 'package:car_alerts/models/car.dart';
import 'package:car_alerts/services/notifications_service.dart';
import 'package:car_alerts/services/notification_permission_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);

class AddOrEditCarScreen extends StatefulWidget {
  final Car? car;

  const AddOrEditCarScreen({super.key, this.car});

  @override
  State<AddOrEditCarScreen> createState() => _AddOrEditCarScreenState();
}

class _AddOrEditCarScreenState extends State<AddOrEditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _carNameController = TextEditingController();
  final NotificationsService _notificationService = NotificationsService();
  String carName = '';
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
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: _teal),
        scaffoldBackgroundColor: _background,
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          title: const Text('YOUR GARAGE',
              style: TextStyle(
                  color: _teal,
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
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Text(widget.car == null ? 'Add a car' : 'Edit car',
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    const SizedBox(height: 6),
                    Text(
                        widget.car == null
                            ? 'A few details now. Fewer surprises later.'
                            : 'Keep your car’s details and deadlines up to date.',
                        style: const TextStyle(color: _muted, fontSize: 14)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: _ink, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.directions_car_outlined,
                            color: Color(0xFF9EDBD0), size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Your car, covered',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(
                                  '$selected ${selected == 1 ? 'document selected' : 'documents selected'} for expiry tracking',
                                  style: const TextStyle(
                                      color: Color(0xFFC3D0D6),
                                      fontSize: 12,
                                      height: 1.5)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    const Text('Car details',
                        style: TextStyle(
                            color: _ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _cardDecoration,
                      child: TextFormField(
                        controller: _carNameController,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1),
                        decoration: InputDecoration(
                          labelText: 'Registration number',
                          hintText: 'e.g. AR00XYZ',
                          helperText: 'Use the number on your licence plate.',
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.directions_car_outlined),
                          filled: true,
                          fillColor: _background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? 'Enter your registration number.'
                            : value.contains('/')
                                ? 'Use a registration number without slashes.'
                                : null,
                        onSaved: (value) => carName = value!.trim(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Documents & expiry dates',
                        style: TextStyle(
                            color: _ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                        'Choose what to track, then add each expiry date.',
                        style: TextStyle(
                            color: _muted, fontSize: 13, height: 1.5)),
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
                    const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 12),
                        child: Text('ROAD VIGNETTES',
                            style: TextStyle(
                                color: _muted,
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
                    const Text('You can add or update documents at any time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: _saveCar,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(
                          widget.car == null ? 'Save car' : 'Save changes',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ))),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0E7EA)));

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
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE0E7EA)),
        ),
        child: Column(children: [
          SwitchListTile.adaptive(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            activeTrackColor: _teal,
            secondary: Icon(icon, color: selected ? _teal : _muted),
            title: Text(title,
                style: const TextStyle(
                    color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle,
                style: const TextStyle(color: _muted, fontSize: 12)),
            value: selected,
            onChanged: onChanged,
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
                        color: _background,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final now = DateTime.now();
                            final initial = date ?? now;
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(
                                  initial.year < 2021 ? initial.year : 2021),
                              lastDate: DateTime(
                                  initial.year > now.year + 15
                                      ? initial.year
                                      : now.year + 15,
                                  12,
                                  31),
                              helpText: '$title expiry',
                              builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.fromSeed(
                                          seedColor: _teal)),
                                  child: child!),
                            );
                            if (picked != null && mounted) {
                              onDateSelected(picked);
                            }
                          },
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: _teal, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      const Text('EXPIRY DATE',
                                          style: TextStyle(
                                              color: _muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text(
                                          date == null
                                              ? 'Choose a date'
                                              : Car.extractDate(
                                                  date.toIso8601String()),
                                          style: const TextStyle(
                                              color: _ink,
                                              fontWeight: FontWeight.w600)),
                                    ])),
                                const Icon(Icons.chevron_right,
                                    color: _muted, size: 20),
                              ])),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(field.errorText!,
                                style: const TextStyle(
                                    color: Color(0xFFAD3939), fontSize: 12))),
                    ]),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _saveCar() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (carName.isEmpty) {
        _showErrorPopUp("Please enter the car name!", errorText);
        return;
      }

      if (widget.car == null) {
        bool nameUsed = await _carNameAlreadyUsed(carName);
        if (!mounted) return;
        if (nameUsed) {
          _showErrorPopUp(
              "You already have a car with this name or identification number saved!",
              errorText);
          return;
        }
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
      await _addCarToDatabase();
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
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(currentUserId)
          .collection('user_cars')
          .doc(carName)
          .set(carData);
    } catch (_) {
      if (mounted) {
        _showErrorPopUp(
            'Could not save your car. Please try again.', errorText);
      }
      return;
    }
    if (!mounted) return;
    String? reminderWarning;
    bool notificationsOff = false;
    if (carData.values.any((value) => value != null)) {
      try {
        final permissions = NotificationPermissionService();
        await permissions.requestIfNotAsked();
        notificationsOff =
            await permissions.status() != NotificationPermission.enabled;
        await _scheduleNotificationsForItems();
      } catch (_) {
        reminderWarning =
            'Your car was saved, but reminders could not be scheduled. Check notification settings and save the car again.';
      }
    }
    if (!mounted) return;
    if (widget.car == null && notificationsOff) {
      _showNotificationsOffReminder(reminderWarning);
      return;
    }
    _showErrorPopUp(
        reminderWarning ??
            (widget.car == null
                ? 'Car successfully added!'
                : 'Car successfully edited!'),
        successText);
  }

  void _showNotificationsOffReminder(String? schedulingWarning) {
    // Capture the app-level messenger before closing the form so the action
    // continues to work on Your Cars, after this State has been disposed.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    mainScreenKey.currentState?.selectTab(1);
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0D1B1E),
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFC3DBC5).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: Color(0xFFC3DBC5), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Turn on reminders',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  schedulingWarning == null
                      ? 'Car saved. Get expiry alerts.'
                      : 'Turn on notifications for expiry reminders.',
                  style: const TextStyle(
                      color: Color(0xFFC3DBC5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Settings',
        textColor: const Color(0xFFC3DBC5),
        onPressed: () async {
          try {
            await NotificationPermissionService().openSettings();
          } catch (_) {
            if (!messenger.mounted) return;
            messenger.showSnackBar(const SnackBar(
              content: Text(
                  'Could not open settings. Enable notifications manually.'),
            ));
          }
        },
      ),
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

  Future<bool> _carNameAlreadyUsed(String carName) async {
    bool result = false;
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .doc(currentUserId)
          .collection('user_cars')
          .doc(carName)
          .get();
      if (snapshot.exists) {
        result = true;
      }
    } catch (error) {
      _showErrorPopUp("Error in querying the database: $error", errorText);
    }
    return result;
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

  Future<void> _scheduleNotificationsForItems() async {
    if (isInsuranceSelected && insuranceExpiringDate != null) {
      await _notificationService.scheduleNotification(
          'insurance', insuranceExpiringDate!, '$carName Insurance Reminder');
    }
    if (isInspectionSelected && inspectionExpiringDate != null) {
      await _notificationService.scheduleNotification('inspection',
          inspectionExpiringDate!, '$carName Inspection Reminder');
    }
    if (isRomanianVignetteSelected && romanianVignetteExpiringDate != null) {
      await _notificationService.scheduleNotification('romanian_vignette',
          romanianVignetteExpiringDate!, '$carName Romanian Vignette Reminder');
    }
    if (isHungarianVignetteSelected && hungarianVignetteExpiringDate != null) {
      await _notificationService.scheduleNotification(
          'hungarian_vignette',
          hungarianVignetteExpiringDate!,
          '$carName Hungarian Vignette Reminder');
    }
    if (isAustrianVignetteSelected && austrianVignetteExpiringDate != null) {
      await _notificationService.scheduleNotification('austrian_vignette',
          austrianVignetteExpiringDate!, '$carName Austrian Vignette Reminder');
    }
  }
}
