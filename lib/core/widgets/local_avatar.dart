import 'dart:io';

import 'package:flutter/material.dart';

import '../services/local_photo_store.dart';
import '../theme/app_theme.dart';

/// Drop-in replacement for a plain CircleAvatar(Icon(Icons.person)) that
/// shows a locally-saved profile photo if one exists for [photoKey]
/// (a band deviceId or a user uid), falling back to the icon otherwise.
class LocalAvatar extends StatelessWidget {
  final String photoKey;
  final double radius;
  final Color backgroundColor;
  final IconData fallbackIcon;
  final Color iconColor;

  const LocalAvatar({
    super.key,
    required this.photoKey,
    this.radius = 22,
    this.backgroundColor = AppColors.background,
    this.fallbackIcon = Icons.person,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LocalPhotoStore.getPhotoPath(photoKey),
      builder: (context, snapshot) {
        final path = snapshot.data;

        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: path != null ? FileImage(File(path)) : null,
          child: path == null
              ? Icon(fallbackIcon, color: iconColor, size: radius)
              : null,
        );
      },
    );
  }
}