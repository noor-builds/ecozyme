import 'package:ecoenzyme/core/router/app_router.dart';
import 'package:ecoenzyme/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://gywqqrcuwhkxxsufpetg.supabase.co",
    publishableKey: "sb_publishable_qxFf5s6Bz1ZMyeW5arbcqg_A9moBHqH",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoEnzyme',
      routerConfig: router ?? appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
