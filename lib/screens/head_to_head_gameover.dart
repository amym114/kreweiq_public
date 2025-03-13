import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class GameOverScreen extends StatelessWidget {
  final String gameId;

  const GameOverScreen({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            color: Color.fromRGBO(236, 230, 240, 1)),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('head_to_head_games')
              .doc(gameId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Extract the game data.
            Map<String, dynamic> gameData =
                snapshot.data!.data() as Map<String, dynamic>;
            String team1Name = gameData['team1_name'];
            String team2Name = gameData['team2_name'];
            int scoreTeam1 = gameData['score_team1'];
            int scoreTeam2 = gameData['score_team2'];

            // Compute the winner based on scores.
            String winner;
            if (scoreTeam1 > scoreTeam2) {
              winner = team1Name;
            } else if (scoreTeam1 < scoreTeam2) {
              winner = team2Name;
            } else {
              winner = 'Tie';
            }

            return SingleChildScrollView(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("images/trophy.png", width: 200),
                      SizedBox(height: 10),
                      Text(
                        winner == 'Tie' ? 'It\'s a tie!' : '$winner for the win!',
                        style: GoogleFonts.shrikhand(
                          fontSize: 38,
                          color: Color(0xFF4A148C)
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                team1Name.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF4A148C)),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '$scoreTeam1',
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF4A148C)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              Text(
                                team2Name.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF4A148C)),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '$scoreTeam2',
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF4A148C)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                        ),
                        onPressed: () {
                          // Navigate to the home or restart screen.
                          GoRouter.of(context).go('/challenge');
                        },
                        child: const Text(
                          'Play Again',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the home or restart screen.
                          GoRouter.of(context).go('/');
                        },
                        child: const Text(
                          'Home',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
