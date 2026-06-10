import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/film_roll.dart';
import '../models/photo.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import 'photo_view_screen.dart';

/// Where rolls go to develop. Undeveloped shots show a countdown instead of
/// a thumbnail; developed shots can be opened full screen.
class DarkroomScreen extends StatefulWidget {
  const DarkroomScreen({super.key});

  @override
  State<DarkroomScreen> createState() => _DarkroomScreenState();
}

class _DarkroomScreenState extends State<DarkroomScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh countdowns (and reveal newly developed photos) periodically.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final rolls = appState.rolls.where((r) => r.photos.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF15130F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15130F),
        foregroundColor: Colors.white,
        title: const Text('Darkroom'),
      ),
      body: rolls.isEmpty
          ? const Center(
              child: Text(
                'No exposures yet.\nGo shoot something!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rolls.length,
              itemBuilder: (context, index) => _RollCard(
                roll: rolls[index],
                isCurrent: rolls[index].id == appState.currentRoll?.id,
              ),
            ),
    );
  }
}

class _RollCard extends StatelessWidget {
  const _RollCard({required this.roll, required this.isCurrent});

  final FilmRoll roll;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Card(
      color: const Color(0xFF26221B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_roll, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCurrent
                        ? 'Current roll • ${formatDate(roll.startedAt)}'
                        : 'Roll of ${formatDate(roll.startedAt)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${roll.shotsTaken}/${roll.capacity}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                  onSelected: (_) => _confirmDeleteRoll(context, appState),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete roll')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final photo in roll.photos.reversed)
                  _PhotoSlot(photo: photo, path: appState.photoPath(photo)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteRoll(
      BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this roll?'),
        content: const Text(
            'All photos on the roll, developed or not, will be gone forever.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await appState.deleteRoll(roll);
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.photo, required this.path});

  final Photo photo;
  final String path;

  @override
  Widget build(BuildContext context) {
    if (!photo.isDeveloped) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3D372C)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_bottom, color: Colors.white24, size: 18),
            const SizedBox(height: 4),
            Text(
              formatCountdown(photo.timeUntilDeveloped),
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotoViewScreen(photo: photo, path: path),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black,
            child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
