import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/initialization_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hyjlsownvikgqhgzhtfq.supabase.co',
    anonKey: 'sb_publishable_wndm3lJNp8fzm48hfqJYhg_7coXThda',
  );

  runApp(const ColdApp());
}

class ColdApp extends StatelessWidget {
  const ColdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InitializationScreen(),
    );
  }
}
