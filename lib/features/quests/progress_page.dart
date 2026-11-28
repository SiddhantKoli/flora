import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/game_rules.dart';
import '../../data/game_store.dart';
import '../../ui/flora_design.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage(
      {super.key,
      required this.state,
      required this.onClaim,
      this.haptics = true});
  final GameSnapshot state;
  final ValueChanged<String> onClaim;
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget progress = _LevelPanel(xp: state.xp);
    if (!reduceMotion) progress = progress.animate().fadeIn(duration: 300.ms);
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        children: [
          const Text('Keep\nlooking.', style: FloraType.display),
          const SizedBox(height: 10),
          Text('The little things you notice add up.',
              style: FloraType.body.copyWith(color: FloraPalette.muted)),
          const SizedBox(height: 28),
          progress,
          const SizedBox(height: 34),
          Text('Side quests', style: FloraType.title),
          const SizedBox(height: 6),
          Text('Optional detours. Your journal is always the main thing.',
              style: FloraType.body
                  .copyWith(color: FloraPalette.muted, fontSize: 13)),
          const SizedBox(height: 18),
          _QuestRow(
              icon: Icons.today_outlined,
              title: 'A new leaf',
              description: 'Save a plant you recognize today.',
              progress: state.dailyProgress,
              target: 1,
              xp: dailyQuestXp,
              claimed: state.dailyClaimed,
              haptics: haptics,
              onClaim: () => onClaim('daily')),
          const SizedBox(height: 10),
          _QuestRow(
              icon: Icons.calendar_view_week_outlined,
              title: 'The week in green',
              description: 'See three different catalog plants this week.',
              progress: state.weeklyProgress,
              target: 3,
              xp: weeklyQuestXp,
              claimed: state.weeklyClaimed,
              haptics: haptics,
              onClaim: () => onClaim('weekly')),
          const SizedBox(height: 24),
          const Divider(color: FloraPalette.line),
          const SizedBox(height: 14),
          Text('How XP works', style: FloraType.title.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
              'First catalog discovery +$firstDiscoveryXp. Another original photo of a catalog plant +$repeatObservationXp, at most once each day. You can save Unknown plants without XP.',
              style: FloraType.body
                  .copyWith(color: FloraPalette.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Text(
              'Quest progress uses names you select yourself and your phone’s local date.',
              style: FloraType.caption),
        ]);
  }
}

class _LevelPanel extends StatelessWidget {
  const _LevelPanel({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: FloraPalette.night, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Level $level',
                      style:
                          FloraType.caption.copyWith(color: FloraPalette.mint)),
                  const SizedBox(height: 6),
                  Text('$xp',
                      style: FloraType.display
                          .copyWith(fontSize: 65, color: Colors.white)),
                  Text('total XP',
                      style: FloraType.body.copyWith(color: Colors.white)),
                ])),
            Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: FloraPalette.signal,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 32)),
          ]),
          const SizedBox(height: 24),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: xpIntoLevel(xp) / 250,
                  minHeight: 7,
                  color: FloraPalette.coral,
                  backgroundColor: Colors.white24)),
          const SizedBox(height: 9),
          Text('${250 - xpIntoLevel(xp)} XP until Level ${level + 1}',
              style: FloraType.caption.copyWith(color: Colors.white)),
        ]));
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow(
      {required this.icon,
      required this.title,
      required this.description,
      required this.progress,
      required this.target,
      required this.xp,
      required this.claimed,
      required this.haptics,
      required this.onClaim});
  final IconData icon;
  final String title;
  final String description;
  final int progress;
  final int target;
  final int xp;
  final bool claimed;
  final bool haptics;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final ready = progress >= target && !claimed;
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: FloraPalette.surface,
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: FloraPalette.signal, size: 25),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(title, style: FloraType.title.copyWith(fontSize: 20))),
            Text('+$xp XP',
                style: FloraType.caption.copyWith(color: FloraPalette.signal)),
          ]),
          const SizedBox(height: 9),
          Text(description, style: FloraType.body.copyWith(fontSize: 13)),
          const SizedBox(height: 17),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: (progress / target).clamp(0, 1),
                  color: FloraPalette.signal,
                  backgroundColor: FloraPalette.line,
                  minHeight: 6)),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
                child: Text('${progress.clamp(0, target)} of $target',
                    style: FloraType.caption)),
            if (claimed)
              Text('Claimed',
                  style: FloraType.caption.copyWith(color: FloraPalette.signal))
            else if (ready)
              TextButton(
                  onPressed: () {
                    if (haptics) HapticFeedback.selectionClick();
                    onClaim();
                  },
                  child: const Text('Claim reward'))
            else
              Text('In progress', style: FloraType.caption),
          ]),
        ]));
  }
}
