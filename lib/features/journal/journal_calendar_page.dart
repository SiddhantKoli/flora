import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/game_store.dart';
import '../../data/observation.dart';
import '../../ui/flora_design.dart';

class JournalCalendarPage extends StatefulWidget {
  const JournalCalendarPage({
    super.key,
    required this.state,
    required this.onOpenVisit,
  });

  final GameSnapshot state;
  final Future<dynamic> Function(Observation) onOpenVisit;

  @override
  State<JournalCalendarPage> createState() => _JournalCalendarPageState();
}

class _JournalCalendarPageState extends State<JournalCalendarPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? selectedDay;

  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Observation> visitsOn(DateTime day) => widget.state.observations
      .where((visit) => sameDay(visit.createdAt.toLocal(), day))
      .toList();

  void moveMonth(int offset) => setState(() {
        month = DateTime(month.year, month.month + offset);
        selectedDay = null;
      });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((firstWeekday - 1 + days + 6) ~/ 7) * 7;
    final selectedVisits =
        selectedDay == null ? <Observation>[] : visitsOn(selectedDay!);
    return Scaffold(
      appBar: AppBar(
          title: Text('Visit calendar',
              style: FloraType.title.copyWith(fontSize: 21))),
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text('YOUR DAYS OUT', style: FloraType.caption),
              const SizedBox(height: 8),
              const Text('Every little\ndiscovery.', style: FloraType.display),
              const SizedBox(height: 12),
              Text('Tap a marked day to revisit its field notes.',
                  style: FloraType.body.copyWith(color: FloraPalette.muted)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: Text('${months[month.month - 1]} ${month.year}',
                        style: FloraType.title.copyWith(fontSize: 22))),
                IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => moveMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded)),
                IconButton(
                    tooltip: 'Next month',
                    onPressed: () => moveMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded)),
              ]),
              const SizedBox(height: 12),
          Row(children: [
                for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                      child:
                          Center(child: Text(label, style: FloraType.caption))),
              ]),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
                itemBuilder: (context, index) {
                  final dayNumber = index - firstWeekday + 2;
                  if (dayNumber < 1 || dayNumber > days)
                    return const SizedBox.shrink();
                  final day = DateTime(month.year, month.month, dayNumber);
                  final count = visitsOn(day).length;
                  final active =
                      selectedDay != null && sameDay(selectedDay!, day);
                  return Semantics(
                    label:
                        '${months[day.month - 1]} ${day.day}, ${day.year}, $count ${count == 1 ? 'visit' : 'visits'}',
                    button: count > 0,
                    selected: active,
                    child: Material(
                      color: active
                          ? FloraPalette.ink
                          : count > 0
                              ? FloraPalette.mint
                              : FloraPalette.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: count == 0
                            ? null
                            : () => setState(() => selectedDay = day),
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text('$dayNumber',
                                  style: FloraType.body.copyWith(
                                      color: active
                                          ? Colors.white
                                          : FloraPalette.ink,
                                      fontWeight: count > 0
                                          ? FontWeight.w800
                                          : FontWeight.w500)),
                              if (count > 0)
                                Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: active
                                            ? FloraPalette.coral
                                            : FloraPalette.signal,
                                        shape: BoxShape.circle)),
                            ])),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 26),
              Text(
                  selectedDay == null
                      ? 'Choose a marked day'
                      : '${selectedVisits.length} ${selectedVisits.length == 1 ? 'visit' : 'visits'} on ${selectedDay!.day} ${months[selectedDay!.month - 1]}',
                  style: FloraType.title.copyWith(fontSize: 20)),
              const SizedBox(height: 10),
              for (final visit in selectedVisits)
                Card(
                    child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(visit.imagePath),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              width: 52,
                              child: Icon(Icons.broken_image_outlined)))),
                  title: Text(
                      widget.state.plantById(visit.plantId)?.displayName ??
                          'Plant visit'),
                  subtitle: Text(
                      TimeOfDay.fromDateTime(visit.createdAt.toLocal())
                          .format(context)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => widget.onOpenVisit(visit),
                )),
            ]),
      ),
    );
  }
}
