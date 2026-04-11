import 'package:chatapp/myapp.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:chatapp/presentation/shared/riverpod/theme_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final sharedPrefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    await initializeOneSignal();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> initializeOneSignal() async {
  if (kIsWeb) return;
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('1232990b-869e-47e2-8838-df1b20038c1a');
  OneSignal.Notifications.requestPermission(true);
}
