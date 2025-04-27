import 'package:flutter/material.dart';
import '../localizations.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('notifications')),
        centerTitle: true,
      ),
      body: Center(
        child: Text(localizations.translate('notifications')),
      ),
    );
  }
}