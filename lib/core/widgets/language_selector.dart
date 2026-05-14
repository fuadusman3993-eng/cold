import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language, color: Colors.white70),
      onPressed: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageItem(context, 'English', const Locale('en')),
              _buildLanguageItem(context, 'العربية', const Locale('ar')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, String name, Locale locale) {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final isSelected = provider.locale == locale;

    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white38,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      onTap: () {
        provider.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}
