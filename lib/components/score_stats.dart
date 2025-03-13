import 'package:flutter/material.dart';

class ScoreStats extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final int totalScore;
  final int level;
  final String player1;
  final String player2;
  final int player1Score;
  final int player2Score;
  final bool isPassAndPlay;

  const ScoreStats(
      {Key? key,
      required this.currentQuestionIndex,
      required this.totalQuestions,
      required this.totalScore,
      required this.level,
      required this.player1,
      required this.player2,
      required this.player1Score,
      required this.player2Score,
      required this.isPassAndPlay})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double sectionFontSize = 12;
    double levelFontSize = 12;
    double labelFontSize = 10;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(62, 15, 114, 1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: isPassAndPlay
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              player1,
                              style: TextStyle(
                                color: const Color.fromRGBO(208, 175, 218, 1),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$player1Score',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sectionFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              player2,
                              style: TextStyle(
                                color: const Color.fromRGBO(208, 175, 218, 1),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$player2Score',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: sectionFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          "TOTAL STARS",
                          style: TextStyle(
                            color: const Color.fromRGBO(208, 175, 218, 1),
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$totalScore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sectionFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    "QUESTION #",
                    style: TextStyle(
                      color: const Color.fromRGBO(208, 175, 218, 1),
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$currentQuestionIndex/$totalQuestions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sectionFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          isPassAndPlay
              ? Container()
              : Expanded(
                  child: Column(
                    children: [
                      Text(
                        "LEVEL",
                        style: TextStyle(
                          color: const Color.fromRGBO(208, 175, 218, 1),
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$level",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: levelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
