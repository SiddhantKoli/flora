import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/game_store.dart';
import '../../data/species.dart';
import '../../ui/flora_design.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.state, required this.onAddPlant});
  final GameSnapshot state;
  final VoidCallback onAddPlant;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String search = '';
  bool seenOnly = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final matches = seedSpecies.where((species) {
      if (seenOnly && !widget.state.unlockedIds.contains(species.id))
        return false;
      return '${species.commonName} ${species.scientificName} ${species.family}'
          .toLowerCase()
          .contains(search.trim().toLowerCase());
    }).toList();
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Row(children: [
              const Text('FLORA',
                  style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -1.1)),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 8, color: FloraPalette.coral),
              const Spacer(),
              Text(
                  '${widget.state.unlockedIds.length.toString().padLeft(2, '0')} / '
                  '${seedSpecies.length.toString().padLeft(2, '0')} seen',
                  style: FloraType.caption.copyWith(color: FloraPalette.ink)),
            ]),
            const SizedBox(height: 32),
            Text('Go find your\nnext favourite.',
                style: FloraType.display.copyWith(fontSize: 42)),
            const SizedBox(height: 12),
            Text('A little more wonder, one photo at a time.',
                style: FloraType.body.copyWith(color: FloraPalette.muted)),
            const SizedBox(height: 24),
            _HeroStory(
                onAddPlant: widget.onAddPlant, reduceMotion: reduceMotion),
            const SizedBox(height: 34),
            Row(children: [
              Expanded(child: Text('The field guide', style: FloraType.title)),
              Text('${matches.length} entries', style: FloraType.caption),
            ]),
            const SizedBox(height: 6),
            Text('A small sample catalog. Names are selected by you.',
                style: FloraType.body
                    .copyWith(color: FloraPalette.muted, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
                onChanged: (value) => setState(() => search = value),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search plants',
                    hintText: 'Name or family')),
            const SizedBox(height: 14),
            Row(children: [
              _filter('All', false),
              const SizedBox(width: 8),
              _filter('Seen', true),
            ]),
            const SizedBox(height: 16),
            if (matches.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(children: [
                    const Icon(Icons.search_off_rounded,
                        color: FloraPalette.muted, size: 42),
                    const SizedBox(height: 12),
                    Text(
                        seenOnly
                            ? 'No catalog plants seen yet.'
                            : 'No matches yet.',
                        style: FloraType.title.copyWith(fontSize: 21)),
                    const SizedBox(height: 6),
                    Text(
                        seenOnly
                            ? 'Take a photo of a plant you know to start.'
                            : 'Try another name or browse all plants.',
                        textAlign: TextAlign.center,
                        style: FloraType.body),
                    if (seenOnly) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: widget.onAddPlant,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Add a plant')),
                    ],
                  ])),
          ]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final species = matches[index];
                final seen = widget.state.unlockedIds.contains(species.id);
                Widget row = _SpeciesRow(
                    species: species,
                    index: seedSpecies.indexOf(species),
                    seen: seen,
                    onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        backgroundColor: FloraPalette.background,
                        builder: (_) =>
                            _SpeciesSheet(species: species, seen: seen)));
                if (!reduceMotion && index < 4) {
                  row = row
                      .animate()
                      .fadeIn(
                          duration: 240.ms,
                          delay: Duration(milliseconds: index * 45))
                      .slideY(
                          begin: .06,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOutCubic);
                }
                return row;
              })),
    ]);
  }

  Widget _filter(String label, bool value) {
    final active = seenOnly == value;
    return Material(
        color: active ? FloraPalette.ink : FloraPalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: () => setState(() => seenOnly = value),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                child: Text(label,
                    style: FloraType.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : FloraPalette.ink)))));
  }
}

class _HeroStory extends StatelessWidget {
  const _HeroStory({required this.onAddPlant, required this.reduceMotion});
  final VoidCallback onAddPlant;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    Widget hero = ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          const Positioned.fill(
              child: ExcludeSemantics(
                  child: Image(
                      image:
                          AssetImage('assets/images/flora_leaf_editorial.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter))),
          const Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC051A1B)])))),
          Padding(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 226),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        const Text('Your world is growing.',
                            style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                                color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('See something interesting? Keep it here.',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 13,
                                color: Colors.white)),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                            onPressed: onAddPlant,
                            style: FilledButton.styleFrom(
                                backgroundColor: FloraPalette.coral,
                                foregroundColor: FloraPalette.ink),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Add a plant')),
                      ]))),
        ]));
    if (!reduceMotion) hero = hero.animate().fadeIn(duration: 350.ms);
    return hero;
  }
}

class _SpeciesRow extends StatelessWidget {
  const _SpeciesRow(
      {required this.species,
      required this.index,
      required this.seen,
      required this.onTap});
  final Species species;
  final int index;
  final bool seen;
  final VoidCallback onTap;

  static const swatches = [
    Color(0xFFCEE7D5),
    Color(0xFFDCE9FF),
    Color(0xFFF5D8CB),
    Color(0xFFE8E6F1),
    Color(0xFFE7E8CF),
    Color(0xFFCAE2E3),
    Color(0xFFF0DFCE),
    Color(0xFFDDE7D4),
  ];

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: FloraPalette.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Container(
                        width: 64,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: swatches[index % swatches.length],
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            species.commonName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: FloraPalette.ink))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(species.commonName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FloraType.body.copyWith(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 3),
                          Text(seen ? 'Seen by you' : species.scientificName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FloraType.caption),
                        ])),
                    if (seen)
                      const Icon(Icons.check_circle_rounded,
                          color: FloraPalette.signal, size: 20),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_outward_rounded,
                        size: 21, color: FloraPalette.ink),
                  ])))));
}

class _SpeciesSheet extends StatelessWidget {
  const _SpeciesSheet({required this.species, required this.seen});
  final Species species;
  final bool seen;

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seen ? 'In your Plantdex' : 'Sample catalog entry',
                    style:
                        FloraType.caption.copyWith(color: FloraPalette.signal)),
                const SizedBox(height: 12),
                Text(species.commonName, style: FloraType.display),
                const SizedBox(height: 5),
                Text(species.scientificName,
                    style: FloraType.body.copyWith(color: FloraPalette.muted)),
                const SizedBox(height: 22),
                const Divider(color: FloraPalette.line),
                const SizedBox(height: 18),
                Text(species.description, style: FloraType.body),
                const SizedBox(height: 20),
                Text('Family: ${species.family}', style: FloraType.caption),
                const SizedBox(height: 20),
                Text(
                    'This catalog is illustrative. Your selection is not an expert identification.',
                    style: FloraType.caption),
              ])));
}
