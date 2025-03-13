import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KreweSelectorScreen extends StatelessWidget {
  
  const KreweSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Krewe Selector")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => GoRouter.of(context).go('/'),
          child: const Text("Back to Menu"),
        ),
      ),
    );
  }
}
