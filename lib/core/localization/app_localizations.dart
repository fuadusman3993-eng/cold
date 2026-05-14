import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = {
    'en': {
      'onboarding_1_title': 'Universal Connectivity',
      'onboarding_1_subtitle': 'A borderless digital ecosystem built for the global community.',
      'onboarding_2_title': 'Visionary Intelligence',
      'onboarding_2_subtitle': 'Advanced algorithms meeting traditional wisdom for modern insights.',
      'onboarding_3_title': 'Inviolable Security',
      'onboarding_3_subtitle': 'Bank-grade encryption anchored in divine protection.',
      'continue': 'Continue',
      'get_started': 'Commence Journey',
      'welcome_title': 'Welcome to the Digital Frontier',
      'welcome_subtitle': 'Authenticate to access your secure ecosystem.',
      'email_hint': 'Email / Username',
      'password_hint': 'Password',
      'forgot_password': 'Recover Access',
      'login_button': 'Authorize',
      'no_account': 'New to the ecosystem? ',
      'sign_up': 'Create Identity',
    },
    'ar': {
      'onboarding_1_title': 'اتصال عالمي',
      'onboarding_1_subtitle': 'نظام بيئي رقمي بلا حدود مبني للمجتمع العالمي.',
      'onboarding_2_title': 'ذكاء رؤيوي',
      'onboarding_2_subtitle': 'خوارزميات متقدمة تلتقي مع الحكمة التقليدية لرؤى حديثة.',
      'onboarding_3_title': 'أمن منيع',
      'onboarding_3_subtitle': 'تشفير بمستوى بنكي مرتكز على الحماية الإلهية.',
      'continue': 'استمرار',
      'get_started': 'ابدأ الرحلة',
      'welcome_title': 'مرحباً بك في الأفق الرقمي',
      'welcome_subtitle': 'قم بالمصادقة للوصول إلى نظامك البيئي الآمن.',
      'email_hint': 'البريد الإلكتروني / اسم المستخدم',
      'password_hint': 'كلمة المرور',
      'forgot_password': 'استعادة الوصول',
      'login_button': 'تفويض',
      'no_account': 'جديد في النظام البيئي؟ ',
      'sign_up': 'إنشاء هوية',
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
