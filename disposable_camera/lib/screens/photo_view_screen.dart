import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';

/// Full-screen view of a developed photo.
class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({super.key, required this.photo, required this.path});

  final Photo photo;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${formatDate(photo.takenAt)} • ${formatTime(photo.takenAt)}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete photo',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: Image.file(
            File(path),
            errorBuilder: (_, __, ___) => const Text(
              'Photo file is missing.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final appState = context.read<AppState>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this photo?'),
        content: const Text('There are no negatives. This cannot be undone.'),
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
    if (confirmed == true) {
      await appState.deletePhoto(photo);
      navigator.pop();
    }
  }
}
