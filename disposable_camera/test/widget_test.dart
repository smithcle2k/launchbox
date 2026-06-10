import 'package:disposable_camera/main.dart';
import 'package:disposable_camera/services/storage_service.dart';
import 'package:disposable_camera/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the camera body without a camera or storage',
      (tester) async {
    // AppState is deliberately not load()ed so no platform channels are hit.
    await tester.pumpWidget(DisposableCameraApp(
      cameras: const [],
      appState: AppState(StorageService()),
    ));

    expect(find.text('SNAP•24'), findsOneWidget);
    expect(find.text('No camera available'), findsOneWidget);
    expect(find.text('SHOTS LEFT'), findsOneWidget);
  });
}
