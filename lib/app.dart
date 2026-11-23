import 'package:flutter/material.dart';
import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';

class NexusStreamApp extends StatelessWidget {
  final AppState state;

  const NexusStreamApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return MaterialApp(
            title: 'NexusStream',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme(accentColor: state.accent.color),
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
