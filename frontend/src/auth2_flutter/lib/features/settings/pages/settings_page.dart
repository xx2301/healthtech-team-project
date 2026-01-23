import 'package:auth2_flutter/features/data/domain/presentation/components/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: DefaultAppBar(),
    );
  }
}