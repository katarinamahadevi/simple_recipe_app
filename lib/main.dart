import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:simple_recipe_app/pages/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Aplikasi Resep',
      home: Homepage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [FlutterQuillLocalizations.delegate],
      supportedLocales: [const Locale('en')],
    );
  }
}
