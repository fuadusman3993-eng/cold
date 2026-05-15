import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'islamic_ai_title': 'Islamic AI Analysis',
      'islamic_ai_subtitle': 'Advanced algorithms aligned with traditional wisdom.',
      'advanced_security_title': 'Advanced Security',
      'advanced_security_subtitle': 'Bank-grade encryption anchored in divine protection.',
      'terms_agreement': 'I agree to the Terms of Service and Privacy Policy',
      'continue': 'Continue',
      'welcome_title': 'Welcome to the Digital Frontier',
      'welcome_subtitle': 'Authenticate to access your secure ecosystem.',
      'email_hint': 'Email / Username',
      'password_hint': 'Password',
      'recover_access': 'Recover Access',
      'authorize': 'Authorize',
      'new_to_ecosystem': 'New to the ecosystem? ',
      'create_identity': 'Create Identity',
    },
    'ar': {
      'islamic_ai_title': 'تحليل الذكاء الاصطناعي الإسلامي',
      'islamic_ai_subtitle': 'خوارزميات متقدمة متوافقة مع الحكمة التقليدية.',
      'advanced_security_title': 'أمن متقدم',
      'advanced_security_subtitle': 'تشفير بمستوى بنكي مرتكز على الحماية الإلهية.',
      'terms_agreement': 'أوافق على شروط الخدمة وسياسة الخصوصية',
      'continue': 'استمرار',
      'welcome_title': 'مرحباً بك في الأفق الرقمي',
      'welcome_subtitle': 'قم بالمصادقة للوصول إلى نظامك البيئي الآمن.',
      'email_hint': 'البريد الإلكتروني / اسم المستخدم',
      'password_hint': 'كلمة المرور',
      'recover_access': 'استعادة الوصول',
      'authorize': 'تفويض',
      'new_to_ecosystem': 'جديد في النظام البيئي؟ ',
      'create_identity': 'إنشاء هوية',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key]!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
