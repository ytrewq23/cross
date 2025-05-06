import 'package:flutter/material.dart';
import '../localizations.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  final List<String> notifications = [
    'Welcome to the app!',
    'Your profile was updated.',
    'New message received.',
    'Reminder: Meeting at 5 PM.',
    'Your report is ready to view.'
  ];

  late final List<AnimationController> _controllers = [];
  late final List<Animation<Offset>> _slideAnimations = [];
  late final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < notifications.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      );

      final slide = Tween<Offset>(
        begin: Offset(1, 0), // from right to left
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));

      _controllers.add(controller);
      _slideAnimations.add(slide);
      _fadeAnimations.add(fade);

      // Stagger animations with delay
      Future.delayed(Duration(milliseconds: i * 300), () {
        controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('notifications')),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return SlideTransition(
            position: _slideAnimations[index],
            child: FadeTransition(
              opacity: _fadeAnimations[index],
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(notifications[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}