import 'package:chatapp/myapp.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeOneSignal();

  runApp(
      const ProviderScope(
          child: MyApp())
  );
}

Future<void> initializeOneSignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('1232990b-869e-47e2-8838-df1b20038c1a');
  OneSignal.Notifications.requestPermission(true);
}





