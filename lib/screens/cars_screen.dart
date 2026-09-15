import 'package:car_alerts/screens/add_or_edit_car_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);

enum _Filter { all, attention }

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  _Filter _filter = _Filter.all;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection('cars')
          .doc(currentUserId)
          .collection('user_cars');
  late final _carsStream = _collection.snapshots();

  Future<void> _edit([Car? car]) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AddOrEditCarScreen(car: car)));
    if (mounted) setState(() {});
  }

  Future<void> _delete(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${car.name}?'),
        content:
            const Text('This car and its saved expiry dates will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep car')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: Color(0xFFAD3939)))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _collection.doc(car.name).delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not remove the car. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _carsStream,
          builder: (context, snapshot) {
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
                          const Text('YOUR GARAGE',
                              style: TextStyle(
                                  color: _teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2)),
                          const SizedBox(height: 10),
                          const Text('Your cars',
                              style: TextStyle(
                                  color: _ink,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1)),
                          const SizedBox(height: 6),
                          const Text('Every car. Every deadline. In one place.',
                              style: TextStyle(color: _muted, fontSize: 14)),
                          const SizedBox(height: 24),
                          if (snapshot.hasData && cars.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: _ink,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(children: [
                                const Icon(Icons.shield_outlined,
                                    color: Color(0xFF9EDBD0), size: 30),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          attentionCount > 0
                                              ? '$attentionCount ${attentionCount == 1 ? 'car needs' : 'cars need'} attention'
                                              : 'No upcoming deadlines',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17)),
                                      const SizedBox(height: 5),
                                      const Text(
                                          'Expired or due within the next 30 days',
                                          style: TextStyle(
                                              color: Color(0xFFC3D0D6),
                                              fontSize: 12)),
                                    ])),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _filterChip(
                                  'All cars · ${cars.length}', _Filter.all),
                              _filterChip('Needs attention · $attentionCount',
                                  _Filter.attention),
                            ]),
                          ],
                        ],
                      )),
                    ),
                    if (snapshot.hasError)
                      const SliverToBoxAdapter(
                          child: _EmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Unable to load your cars',
                              description:
                                  'Check your connection and reopen this page.'))
                    else if (!snapshot.hasData)
                      const SliverToBoxAdapter(
                          child: Padding(
                              padding: EdgeInsets.all(64),
                              child: Center(
                                  child:
                                      CircularProgressIndicator(color: _teal))))
                    else if (visible.isEmpty)
                      SliverToBoxAdapter(
                          child: _EmptyState(
                        icon: cars.isEmpty
                            ? Icons.directions_car_outlined
                            : Icons.check_circle_outline,
                        title: cars.isEmpty
                            ? 'Your garage starts here'
                            : 'Nothing needs attention',
                        description: cars.isEmpty
                            ? 'Add your first car to keep insurance, inspections and vignettes together.'
                            : 'No saved dates are expired or due in the next 30 days.',
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
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add car',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _filterChip(String label, _Filter filter) => ChoiceChip(
        label: Text(label),
        selected: _filter == filter,
        selectedColor: const Color(0xFFDDEEEA),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
            color: _filter == filter ? _teal : _muted,
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
  final days = car.items.values.map(_days).whereType<int>().toList()..sort();
  return days.isEmpty ? 999999 : days.first;
}

bool _needsAttention(Car car) => car.items.values.any((value) {
      final days = _days(value);
      return days != null && days <= 30;
    });

String _label(String key) {
  final label = key.replaceAll('_date', '').replaceAll('_', ' ');
  return label.isEmpty
      ? 'Document'
      : '${label[0].toUpperCase()}${label.substring(1)}';
}

class _CarCard extends StatelessWidget {
  const _CarCard(
      {required this.car, required this.onEdit, required this.onDelete});
  final Car car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entries = car.items.entries.toList()
      ..sort((a, b) =>
          (_days(a.value) ?? 999999).compareTo(_days(b.value) ?? 999999));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E7EA))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _background, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.directions_car_outlined,
                  color: _ink, size: 28)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(car.name,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                    '${entries.length} ${entries.length == 1 ? 'document' : 'documents'} tracked',
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ])),
        ]),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFEAF0F2))),
        if (entries.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Add expiry dates to start tracking this car.',
                  style: TextStyle(color: _muted))),
        ...entries.map((entry) {
          final days = _days(entry.value);
          final color = days == null
              ? _muted
              : days < 0
                  ? const Color(0xFFAD3939)
                  : days <= 30
                      ? const Color(0xFF94600E)
                      : _teal;
          final status = days == null
              ? 'Check date'
              : days < 0
                  ? '${days.abs()}d overdue'
                  : days == 0
                      ? 'Due today'
                      : days <= 30
                          ? 'Due in ${days}d'
                          : 'Up to date';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: LayoutBuilder(builder: (context, constraints) {
              final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(entry.key),
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        days == null
                            ? 'Update this expiry date'
                            : Car.extractDate(entry.value),
                        style: const TextStyle(color: _muted, fontSize: 12)),
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
        const Divider(height: 16, color: Color(0xFFEAF0F2)),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          children: [
            TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove car'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFAD3939))),
            TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Manage car'),
                style: TextButton.styleFrom(foregroundColor: _teal)),
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
          Icon(icon, size: 56, color: _teal),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _ink, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5)),
        ]),
      );
}
