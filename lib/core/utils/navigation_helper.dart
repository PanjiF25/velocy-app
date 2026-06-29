import 'package:flutter/material.dart';

import 'package:velocy_app/ui/user/home_screen.dart';
import 'package:velocy_app/ui/user/profile/profile_screen.dart';
import 'package:velocy_app/ui/user/rent/rent_screen.dart';
import 'package:velocy_app/ui/user/history/trip_screen.dart';

Route<void> _instantRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => page,
  );
}

Future<void> switchToTab(BuildContext context, int index) async {
  late final Widget page;

  switch (index) {
    case 0:
      page = const HomeScreen();
      break;
    case 1:
      page = const RentScreen();
      break;
    case 2:
      page = const TripScreen();
      break;
    case 3:
      page = const ProfileScreen();
      break;
    default:
      return;
  }

  await Navigator.of(context).pushAndRemoveUntil(_instantRoute(page), (route) => false);
}
