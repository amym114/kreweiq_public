import 'package:flutter/material.dart';

class Scoreboard extends StatelessWidget {
  const Scoreboard({
    Key? key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.totalScore,
    required this.category,
    required this.level,
    required this.currentQuestionPoints,
    required this.remainingFraction,
    this.playerTurn = '',
  }) : super(key: key);

  final int currentQuestionIndex;
  final int totalQuestions;
  final int totalScore;
  final String category;
  final int level;
  final int currentQuestionPoints;
  final double remainingFraction;
  final String playerTurn; // New parameter

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double sectionFontSize = screenWidth > 600 ? 12 : 14;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(123, 1, 161, 1.0),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (playerTurn.isNotEmpty) ...[
                  Text(
                    playerTurn,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sectionFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      width: 8), // Spacing between the text and stars.
                ],
                // Generate the stars.
                ...List.generate(5, (index) {
                  return Icon(
                    index < currentQuestionPoints
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.yellow,
                    size: 20,
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            // Animated progress bar anchored to the left.
            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: constraints.maxWidth * remainingFraction,
                    height: 3,
                    color: Colors.yellow,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Additional score sections can be added below.
          ],
        ),
      ),
    );
  }
}
