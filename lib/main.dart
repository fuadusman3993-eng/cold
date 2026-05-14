import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cold/core/theme/app_theme.dart';
import 'package:cold/core/widgets/initialization_screen.dart';
import 'package:cold/core/localization/locale_provider.dart';
import 'package:cold/core/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hyjlsownvikgqhgzhtfq.supabase.co',
    anonKey: 'sb_publishable_wndm3lJNp8fzm48hfqJYhg_7coXThda',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const ColdApp(),
    ),
  );
}

class ColdApp extends StatelessWidget {
  const ColdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Cold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const InitializationScreen(),
    );
  }
}
