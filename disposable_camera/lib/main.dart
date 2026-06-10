import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/camera_screen.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = <CameraDescription>[];
  try {
    cameras.addAll(await availableCameras());
  } on CameraException {
    // No camera on this device; the camera screen shows a placeholder.
  }
  final appState = AppState(StorageService());
  await appState.load();
  runApp(DisposableCameraApp(cameras: cameras, appState: appState));
}

class DisposableCameraApp extends StatelessWidget {
  const DisposableCameraApp({
    super.key,
    required this.cameras,
    required this.appState,
  });

  final List<CameraDescription> cameras;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Snap 24',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF15130F),
          useMaterial3: true,
        ),
        home: CameraScreen(cameras: cameras),
      ),
    );
  }
}
