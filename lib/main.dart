import 'dart:io';

import 'package:flutter/material.dart';
import 'package:business_assistant/app.dart';
import 'package:business_assistant/core/di/injection_container.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initDependencyInjection();
  runApp(const App());
}
