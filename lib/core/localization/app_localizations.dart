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
      'islamic_ai_subtitle': 'Utilizing earthly creations for virtue as commanded by Allah. Dedicated to filtering, restricting, and monitoring prohibited (Haram) content.',
      'advanced_security_title': 'Advanced Security',
      'advanced_security_subtitle': 'Enforcing Amanah through bank-grade encryption and strict security protocols to safeguard your digital sanctuary.',
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
      'islamic_ai_subtitle': 'استخدام المخلوقات الأرضية للخير كما أمر الله. مخصص لتصفية وتقييد ومراقبة المحتوى المحرم.',
      'advanced_security_title': 'أمن متقدم',
      'advanced_security_subtitle': 'إنفاذ الأمانة من خلال تشفير بمستوى بنكي وبروتوكولات أمنية صارمة لحماية ملاذك الرقمي.',
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
