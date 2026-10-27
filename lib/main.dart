import 'package:field_service/app.dart';
import 'package:field_service/core/config/api_config.dart';
import 'package:field_service/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  ApiConfig.validate();

  await Supabase.initialize(
    url: ApiConfig.url,
    publishableKey: ApiConfig.publishableKey,
  );

  setupDependencies();

  runApp(const FsmApp());
}
