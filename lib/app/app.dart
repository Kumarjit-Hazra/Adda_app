import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class AddaApp extends ConsumerWidget {
  const AddaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ADDA',
      debugShowCheckedModeBanner: false,
      theme: AddaTheme.lightTheme,
      darkTheme: AddaTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
