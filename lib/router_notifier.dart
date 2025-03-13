import 'package:flutter/material.dart';

class RouterNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners(); // 🔥 Forces a rebuild of GoRouter
  }
}
