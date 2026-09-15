import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/car.dart';
import 'add_or_edit_car_screen.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);
const _red = Color(0xFFAD3939);
const _amber = Color(0xFF94600E);

enum _DeadlineFilter { attention, upcoming, all }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _DeadlineFilter _filter = _DeadlineFilter.attention;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _stream = FirebaseFirestore.instance
        .collection('cars')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('user_cars')
        .snapshots();
  }

  Future<void> _edit([Car? car]) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AddOrEditCarScreen(car: car)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName
        ?.trim()
        .split(RegExp(r'\s+'))
        .first;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            final cars = snapshot.data?.docs
                    .map((doc) => Car.fromMap(doc.data(), doc.id))
                    .toList() ??
                <Car>[];
            final deadlines = cars
                .expand((car) => car.items.entries
                    .map((entry) => _Deadline(car, entry.key, entry.value)))
                .toList()
              ..sort((a, b) {
                final order = (a.days ?? -999999).compareTo(b.days ?? -999999);
                return order != 0 ? order : a.car.name.compareTo(b.car.name);
              });
            final overdue =
                deadlines.where((d) => d.days != null && d.days! < 0).length;
            final soon = deadlines
                .where((d) => d.days != null && d.days! >= 0 && d.days! <= 30)
                .length;
            final invalid = deadlines.where((d) => d.days == null).length;
            final attention = overdue + soon + invalid;
            final visible = deadlines
                .where((d) => switch (_filter) {
                      _DeadlineFilter.attention =>
                        d.days == null || d.days! <= 30,
                      _DeadlineFilter.upcoming =>
                        d.days != null && d.days! >= 0,
                      _DeadlineFilter.all => true,
                    })
                .toList();
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  sliver: SliverToBoxAdapter(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AT A GLANCE',
                          style: TextStyle(
                              color: _teal,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                      const SizedBox(height: 10),
                      Text(
                          name == null || name.isEmpty
                              ? 'Hello there'
                              : 'Hello, $name',
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 6),
                      const Text('A little planning. A smoother journey.',
                          style: TextStyle(color: _muted, fontSize: 14)),
                      if (snapshot.hasData && !snapshot.hasError) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.shield_outlined,
                                    color: Color(0xFF9EDBD0), size: 30),
                                const SizedBox(height: 18),
                                Text(
                                    deadlines.isEmpty
                                        ? 'Make room for peace of mind'
                                        : attention > 0
                                            ? '$attention ${attention == 1 ? 'deadline needs' : 'deadlines need'} attention'
                                            : 'You’re ahead of your deadlines',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Text(
                                    deadlines.isEmpty
                                        ? 'Keep track of insurance, inspections and vignettes for every car.'
                                        : attention > 0
                                            ? 'Review expired documents and dates due in the next 30 days.${invalid > 0 ? ' $invalid saved dates also need checking.' : ''}'
                                            : 'No saved dates are expired or due in the next 30 days.',
                                    style: const TextStyle(
                                        color: Color(0xFFC3D0D6),
                                        fontSize: 13,
                                        height: 1.5)),
                                const SizedBox(height: 14),
                                TextButton.icon(
                                  onPressed: cars.isEmpty
                                      ? () => _edit()
                                      : () => mainScreenKey.currentState
                                          ?.selectTab(1),
                                  style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF9EDBD0),
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft),
                                  icon: Icon(
                                      cars.isEmpty
                                          ? Icons.add
                                          : Icons.arrow_forward,
                                      size: 18),
                                  label: Text(cars.isEmpty
                                      ? 'Add your first car'
                                      : 'View your garage'),
                                ),
                              ]),
                        ),
                        if (deadlines.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            final tiles = [
                              _stat('$overdue', 'Overdue', _red),
                              _stat('$soon', 'Due in 30 days', _amber),
                              _stat(
                                  '${cars.length}',
                                  cars.length == 1
                                      ? 'Car tracked'
                                      : 'Cars tracked',
                                  _teal),
                            ];
                            if (constraints.maxWidth < 300 ||
                                MediaQuery.textScalerOf(context).scale(14) >
                                    20) {
                              return Wrap(
                                  spacing: 10, runSpacing: 10, children: tiles);
                            }
                            return Row(children: [
                              Expanded(child: tiles[0]),
                              const SizedBox(width: 10),
                              Expanded(child: tiles[1]),
                              const SizedBox(width: 10),
                              Expanded(child: tiles[2])
                            ]);
                          }),
                          const SizedBox(height: 28),
                          const Text('Your deadlines',
                              style: TextStyle(
                                  color: _ink,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text(
                              'The most urgent dates come first. Tap to manage.',
                              style: TextStyle(color: _muted, fontSize: 12)),
                          const SizedBox(height: 14),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _chip('Needs attention · $attention',
                                _DeadlineFilter.attention),
                            _chip('Upcoming', _DeadlineFilter.upcoming),
                            _chip('All', _DeadlineFilter.all),
                          ]),
                        ],
                      ],
                    ],
                  ))),
              if (snapshot.hasError)
                SliverToBoxAdapter(
                    child: _message(
                        Icons.cloud_off_outlined,
                        'Unable to load your dashboard',
                        'Check your connection and try again.',
                        action: TextButton(
                            onPressed: () => setState(_connect),
                            child: const Text('Try again'))))
              else if (!snapshot.hasData)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(64),
                        child: Center(
                            child: CircularProgressIndicator(color: _teal))))
              else if (deadlines.isEmpty)
                SliverToBoxAdapter(
                    child: _message(
                        Icons.event_note_outlined,
                        'No deadlines yet',
                        cars.isEmpty
                            ? 'Your saved expiry dates will appear here once you add a car.'
                            : 'Open your garage and add expiry dates to your cars.'))
              else if (visible.isEmpty)
                SliverToBoxAdapter(
                    child: _message(
                        Icons.check_circle_outline,
                        _filter == _DeadlineFilter.attention
                            ? 'Nothing needs attention'
                            : 'No upcoming deadlines',
                        _filter == _DeadlineFilter.attention
                            ? 'Take a look at Upcoming to plan your next renewal.'
                            : 'Your saved dates are in the past. Update them after renewing.'))
              else
                SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                      (context, index) => _deadlineCard(visible[index]),
                      childCount: visible.length,
                    ))),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ]);
          },
        ),
      ))),
    );
  }

  Widget _chip(String label, _DeadlineFilter filter) => ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        selectedColor: const Color(0xFFDDEEEA),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
            color: _filter == filter ? _teal : _muted,
            fontWeight: FontWeight.w600),
        onSelected: (_) => setState(() => _filter = filter),
      );

  Widget _stat(String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7EA))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
      );

  Widget _deadlineCard(_Deadline deadline) {
    final days = deadline.days;
    final color = days == null
        ? _muted
        : days < 0
            ? _red
            : days <= 30
                ? _amber
                : _teal;
    final status = days == null
        ? 'Check date'
        : days < 0
            ? '${days.abs()}d overdue'
            : days == 0
                ? 'Due today'
                : 'Due in ${days}d';
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE0E7EA))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => _edit(deadline.car),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                              deadline.key.contains('insurance')
                                  ? Icons.shield_outlined
                                  : deadline.key.contains('inspection')
                                      ? Icons.build_outlined
                                      : Icons.confirmation_number_outlined,
                              color: color,
                              size: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(deadline.label,
                                style: const TextStyle(
                                    color: _ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Text(deadline.car.name,
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.09),
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                      child: Text(status,
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700))),
                                  if (days != null)
                                    Text(Car.extractDate(deadline.value),
                                        style: const TextStyle(
                                            color: _muted, fontSize: 12)),
                                ]),
                          ])),
                      const Icon(Icons.chevron_right, color: _muted, size: 20),
                    ]),
              )),
        ));
  }

  Widget _message(IconData icon, String title, String description,
          {Widget? action}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(children: [
          Icon(icon, size: 48, color: _teal),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _ink, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5)),
          if (action != null) action,
        ]),
      );
}

class _Deadline {
  _Deadline(this.car, this.key, this.value) {
    final date = DateTime.tryParse(value);
    final now = DateTime.now();
    days = date == null
        ? null
        : DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(now.year, now.month, now.day))
            .inDays;
  }
  final Car car;
  final String key;
  final String value;
  late final int? days;
  String get label {
    final text = key.replaceAll('_date', '').replaceAll('_', ' ');
    return text.isEmpty
        ? 'Document'
        : '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
