import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/develop_schedule.dart';
import '../state/app_state.dart';
import 'darkroom_screen.dart';

/// The camera body: a small viewfinder, a wind-down exposure counter, flash
/// toggle, and a big shutter button. No photo preview, ever.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _flashOn = false;
  bool _shutterFlash = false;
  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraIndex = widget.cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (_cameraIndex < 0) _cameraIndex = 0;
    _initController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      _initController();
    }
  }

  Future<void> _initController() async {
    if (widget.cameras.isEmpty) return;
    final controller = CameraController(
      widget.cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      await controller
          .setFlashMode(_flashOn ? FlashMode.always : FlashMode.off);
    } on CameraException {
      await controller.dispose();
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    controller.addListener(_handleCameraValueChanged);
    setState(() => _controller = controller);
  }

  /// The UI is locked to portrait, but the camera plugin still reports the
  /// physical orientation; the buttons counter-rotate to stay upright, like
  /// the iOS camera app.
  void _handleCameraValueChanged() {
    final orientation = _controller?.value.deviceOrientation;
    if (orientation != null && orientation != _deviceOrientation && mounted) {
      setState(() => _deviceOrientation = orientation);
    }
  }

  double get _iconTurns => switch (_deviceOrientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeLeft => 0.25,
        DeviceOrientation.portraitDown => 0.5,
        DeviceOrientation.landscapeRight => -0.25,
      };

  Future<void> _toggleFlash() async {
    setState(() => _flashOn = !_flashOn);
    try {
      await _controller
          ?.setFlashMode(_flashOn ? FlashMode.always : FlashMode.off);
    } on CameraException {
      // Some cameras (e.g. front) have no flash; the toggle is cosmetic then.
    }
  }

  Future<void> _flipCamera() async {
    if (widget.cameras.length < 2) return;
    final old = _controller;
    setState(() => _controller = null);
    await old?.dispose();
    _cameraIndex = (_cameraIndex + 1) % widget.cameras.length;
    await _initController();
  }

  Future<void> _shoot() async {
    final appState = context.read<AppState>();
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        appState.isProcessing ||
        appState.currentRoll == null) {
      return;
    }
    setState(() => _shutterFlash = true);
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _shutterFlash = false);
    });
    try {
      final file = await controller.takePicture();
      await appState.capture(await file.readAsBytes());
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not take photo: ${e.description}')),
      );
    }
  }

  void _openDarkroom() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DarkroomScreen()),
    );
  }

  void _openSettings() {
    final appState = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Photos develop',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              for (final speed in DevelopSpeed.values)
                RadioListTile<DevelopSpeed>(
                  title: Text(speed.label),
                  value: speed,
                  groupValue: appState.developSpeed,
                  onChanged: (value) {
                    if (value != null) appState.setDevelopSpeed(value);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final roll = appState.currentRoll;

    return Scaffold(
      backgroundColor: const Color(0xFF15130F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TopBar(
                turns: _iconTurns,
                flashOn: _flashOn,
                onToggleFlash: _toggleFlash,
                onFlipCamera: widget.cameras.length > 1 ? _flipCamera : null,
                onOpenSettings: _openSettings,
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildViewfinder(appState)),
              const SizedBox(height: 16),
              _BottomBar(
                turns: _iconTurns,
                shotsLeft: roll?.shotsLeft ?? 0,
                developingCount: appState.developingCount,
                canShoot: roll != null &&
                    !appState.isProcessing &&
                    _controller != null,
                onShoot: _shoot,
                onOpenDarkroom: _openDarkroom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder(AppState appState) {
    final controller = _controller;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF26221B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3D372C), width: 3),
      ),
      padding: const EdgeInsets.all(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 100,
                  height: controller.value.previewSize?.width ?? 100,
                  child: CameraPreview(controller),
                ),
              )
            else
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Text(
                  widget.cameras.isEmpty
                      ? 'No camera available'
                      : 'Loading camera…',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            if (_shutterFlash) Container(color: Colors.white),
            if (appState.currentRoll == null) _RollFinishedOverlay(
              onNewRoll: appState.startNewRoll,
            ),
            if (appState.isProcessing)
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _WindingIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.turns,
    required this.flashOn,
    required this.onToggleFlash,
    required this.onFlipCamera,
    required this.onOpenSettings,
  });

  final double turns;
  final bool flashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback? onFlipCamera;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onToggleFlash,
          icon: _Rotates(
            turns: turns,
            child: Icon(
              flashOn ? Icons.flash_on : Icons.flash_off,
              color: flashOn ? Colors.amber : Colors.white38,
            ),
          ),
          tooltip: 'Flash',
        ),
        const Spacer(),
        const Text(
          'SNAP•24',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onFlipCamera,
          icon: _Rotates(
            turns: turns,
            child: const Icon(Icons.cameraswitch, color: Colors.white38),
          ),
          tooltip: 'Flip camera',
        ),
        IconButton(
          onPressed: onOpenSettings,
          icon: _Rotates(
            turns: turns,
            child: const Icon(Icons.tune, color: Colors.white38),
          ),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.turns,
    required this.shotsLeft,
    required this.developingCount,
    required this.canShoot,
    required this.onShoot,
    required this.onOpenDarkroom,
  });

  final double turns;
  final int shotsLeft;
  final int developingCount;
  final bool canShoot;
  final VoidCallback onShoot;
  final VoidCallback onOpenDarkroom;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ExposureCounter(turns: turns, shotsLeft: shotsLeft),
        _ShutterButton(turns: turns, enabled: canShoot, onPressed: onShoot),
        _DarkroomButton(
          turns: turns,
          developingCount: developingCount,
          onPressed: onOpenDarkroom,
        ),
      ],
    );
  }
}

/// The little mechanical wind-down counter showing exposures left.
class _ExposureCounter extends StatelessWidget {
  const _ExposureCounter({required this.turns, required this.shotsLeft});

  final double turns;
  final int shotsLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF26221B),
            border: Border.all(color: const Color(0xFF3D372C), width: 3),
          ),
          child: _Rotates(
            turns: turns,
            child: Text(
              '$shotsLeft',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'SHOTS LEFT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.turns,
    required this.enabled,
    required this.onPressed,
  });

  final double turns;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
            border: Border.all(color: const Color(0xFF8A6D1C), width: 5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: _Rotates(
            turns: turns,
            child:
                const Icon(Icons.camera_alt, color: Color(0xFF2B2410), size: 34),
          ),
        ),
      ),
    );
  }
}

class _DarkroomButton extends StatelessWidget {
  const _DarkroomButton({
    required this.turns,
    required this.developingCount,
    required this.onPressed,
  });

  final double turns;
  final int developingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Badge(
          isLabelVisible: developingCount > 0,
          label: Text('$developingCount'),
          child: IconButton(
            onPressed: onPressed,
            iconSize: 34,
            icon: _Rotates(
              turns: turns,
              child: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white70,
              ),
            ),
            tooltip: 'Darkroom',
          ),
        ),
        const Text(
          'DARKROOM',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Spins a control in place to match the physical device orientation while
/// the screen itself stays portrait.
class _Rotates extends StatelessWidget {
  const _Rotates({required this.turns, required this.child});

  final double turns;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: turns,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: child,
    );
  }
}

class _RollFinishedOverlay extends StatelessWidget {
  const _RollFinishedOverlay({required this.onNewRoll});

  final VoidCallback onNewRoll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_roll, color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          const Text(
            'ROLL FINISHED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your shots are developing in the darkroom.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onNewRoll,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF2B2410),
            ),
            child: const Text('Load a new roll'),
          ),
        ],
      ),
    );
  }
}

class _WindingIndicator extends StatelessWidget {
  const _WindingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
          ),
          SizedBox(width: 8),
          Text('Winding…', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
