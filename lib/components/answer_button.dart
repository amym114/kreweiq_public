import 'package:flutter/material.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 976),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * .9, // ✅ 90% of screen width

        child: ElevatedButton(
          
          onPressed: onTap,
          onHover: (hovering) {},
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty .resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.hovered)) {
                  // Change the background color when hovered
                  return Color.fromARGB(255, 241, 222, 255);
                }
                // Default background color
                return const Color.fromARGB(255, 231, 207, 248);
              },
            ),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A148C),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).showCursorOnHover,
      ),
    );
  }
}
