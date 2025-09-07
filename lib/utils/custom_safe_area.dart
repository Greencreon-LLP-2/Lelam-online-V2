import 'package:flutter/material.dart';

Widget CustomSafeArea({required Widget child}) {
  return SafeArea(
    top: true,
    bottom: true,
    left: true,
    right: true,
    minimum: const EdgeInsets.only(top: 16, bottom: 16, left: 0, right: 0),
    child: child,
  );
}
