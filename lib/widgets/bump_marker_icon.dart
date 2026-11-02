import 'package:flutter/material.dart';

/// Black teardrop pin with a white dot, matching the .bump-marker CSS.
class BumpMarkerIcon extends StatelessWidget {
  const BumpMarkerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398, // -45deg, matches CSS rotate(-45deg)
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.45),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
