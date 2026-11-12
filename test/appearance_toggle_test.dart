import 'package:cartboat/core/storage/prefs.dart';
import 'package:cartboat/core/theme/app_theme.dart';
import 'package:cartboat/features/account/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('appearance labels are vertically centred in the track', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(theme: AppTheme.dark(), home: const AccountScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.dragUntilVisible(find.text('Auto'), find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump(const Duration(seconds: 1));

    for (final label in ['Auto', 'Light', 'Dark']) {
      final text = tester.getRect(find.text(label));
      final track = tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(Stack)).first,
      );
      expect((text.center.dy - track.center.dy).abs(), lessThan(1.5), reason: '$label text $text in track $track');
    }
  });
}
