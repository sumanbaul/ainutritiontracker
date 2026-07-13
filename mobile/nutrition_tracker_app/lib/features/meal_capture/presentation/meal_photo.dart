import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../data/meal_image_repository.dart';

class MealPhoto extends ConsumerWidget {
  const MealPhoto({
    super.key,
    required this.mealId,
    required this.hasImage,
    this.fit = BoxFit.cover,
    this.hero = false,
  });
  final String mealId;
  final bool hasImage;
  final BoxFit fit;
  final bool hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = hasImage
        ? FutureBuilder<Uint8List?>(
            future: ref.watch(mealImageRepositoryProvider).get(mealId),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              return AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild
                  ],
                ),
                child: bytes != null && bytes.isNotEmpty
                    ? SizedBox.expand(
                        key: ValueKey(mealId),
                        child: Image.memory(bytes,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            fit: fit,
                            gaplessPlayback: true),
                      )
                    : _placeholder(context),
              );
            },
          )
        : _placeholder(context);
    final expanded = SizedBox.expand(child: image);
    return hero ? Hero(tag: 'meal-image-$mealId', child: expanded) : expanded;
  }

  Widget _placeholder(BuildContext context) => SizedBox.expand(
        child: Container(
          key: const ValueKey('meal-placeholder'),
          decoration: const BoxDecoration(gradient: AppGradients.hero),
          child: Center(
            child: Icon(Icons.restaurant_rounded,
                size: 58, color: Colors.white.withOpacity(.76)),
          ),
        ),
      );
}
