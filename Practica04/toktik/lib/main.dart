import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktik/config/presentation/providers/discover_provider.dart';
import 'package:toktik/config/presentation/screens/discover/discover_screen.dart';
import 'package:toktik/config/theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiscoverProvider(),)
      ],
      child: MaterialApp(
      title: 'TokTik',
      debugShowCheckedModeBanner:false,
      theme: AppTheme().getTheme(),
      home: const DiscoverScreen()
    ));
  }
}