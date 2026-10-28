import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';

/// Full-bleed brand splash, shown while a stored session is validated.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Matches the top of the artwork so the native launch screen blends in.
  static const Color backgroundColor = Color(0xFFAED0F2);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash.png', fit: BoxFit.cover),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
