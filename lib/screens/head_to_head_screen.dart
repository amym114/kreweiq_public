import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class HeadToHeadGameScreen extends StatefulWidget {
  final String gameId;
  const HeadToHeadGameScreen({Key? key, required this.gameId})
      : super(key: key);

  @override
  _HeadToHeadGameScreenState createState() => _HeadToHeadGameScreenState();
}

class _HeadToHeadGameScreenState extends State<HeadToHeadGameScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? gameData;
  bool loading = true;

  // Game state
  int currentWordIndex = 0;
  late int roundTime; // seconds per round (from gameData)
  Timer? roundTimer;
  int remainingTime = 0;

  // Pre-round countdown
  bool countdownActive = true;
  int countdownValue = 3;

  // Whether the round is active (i.e. timer running)
  bool roundActive = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  void _loadGame() async {
    gameData = await _firestoreService.fetchGame(widget.gameId);
    if (gameData != null) {
      setState(() {
        loading = false;
        // Use seconds_per_turn from game data (default to 60 seconds)
        roundTime = gameData!['seconds_per_turn'] ?? 60;
        remainingTime = roundTime;
      });
      _startPreRoundCountdown();
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  /// Starts a 3-2-1 countdown before the round starts.
  /// If [resumeTime] is provided, it resumes with that remaining time.
  void _startPreRoundCountdown({int? resumeTime}) {
    // Use resumeTime if it’s > 0, otherwise use the full roundTime.
    int newTime =
        (resumeTime != null && resumeTime > 0) ? resumeTime : roundTime;
    setState(() {
      countdownActive = true;
      countdownValue = 3;
      roundActive = false;
      remainingTime = newTime;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownValue == 1) {
        timer.cancel();
        setState(() {
          countdownActive = false;
          roundActive = true;
        });
        _startRoundTimer(startTime: remainingTime);
      } else {
        setState(() {
          countdownValue--;
        });
      }
    });
  }

  /// Starts the round timer for the entire round, beginning at [startTime].
  void _startRoundTimer({int? startTime}) {
    remainingTime = startTime ?? roundTime;
    roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == 0) {
        timer.cancel();
        _endRound();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  /// Called when the round timer reaches 0.
  void _endRound() async {
    setState(() {
      roundActive = false;
    });
    // Update the turn in Firestore (false indicates no correct guess this round)
    await _firestoreService.updateTurn(
        gameId: widget.gameId, correctGuess: false);
    // Re-fetch the updated game data
    gameData = await _firestoreService.fetchGame(widget.gameId);
    setState(() {});

    // If the game is over, navigate immediately to the game over screen.
    if (gameData!['status'] == 'completed') {
      GoRouter.of(context).go('/challenge/gameover/${widget.gameId}');
      return;
    }

    // Otherwise, prompt to pass the phone to the other team.
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text("Time's up!"),
        content: const Text("Pass the phone to the other team!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextRound(gameData!['seconds_per_turn'] ?? 60);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _nextWordWithCountdown() {
    List words = gameData!['words'];
    setState(() {
      currentWordIndex = (currentWordIndex + 1) % words.length;
    });
    _startPreRoundCountdown(resumeTime: remainingTime);
  }

  void _nextRound(int newRoundTime) {
    if (gameData!['status'] == 'completed') {
      GoRouter.of(context).go('/challenge/gameover/${widget.gameId}');
      return;
    }
    List words = gameData!['words'];
    setState(() {
      currentWordIndex = (currentWordIndex + 1) % words.length;
    });
    _startPreRoundCountdown(resumeTime: newRoundTime);
  }

  /// Mark the current word as correctly guessed.
  void _markWordCorrect() async {
    if (roundTimer?.isActive ?? false) {
      roundTimer!.cancel();
    }
    // Update score in Firestore here
    await _firestoreService.updateScore(
        gameId: widget.gameId, correctGuess: true);
    _nextWordWithCountdown();
  }

  /// Skip the current word.
  void _skipWord() {
    if (roundTimer?.isActive ?? false) {
      roundTimer!.cancel();
    }
    _nextWordWithCountdown();
  }

  @override
  void dispose() {
    roundTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // While we're still loading the initial gameData, show a loading indicator.
    if (loading || gameData == null) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    List words = gameData!['words'];
    if (currentWordIndex >= words.length) {
      // Optionally, schedule navigation to gameover or show a placeholder.
      return Container(); // or trigger navigation safely.
    }
    String currentWord = words[currentWordIndex]['word'] ?? "Word";

    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            color: Color.fromRGBO(236, 230, 240, 1)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Firestore listener for scoreboard
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('head_to_head_games')
                        .doc(widget.gameId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      Map<String, dynamic> gameDoc =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String team1Name = gameDoc['team1_name'];
                      String team2Name = gameDoc['team2_name'];
                      int scoreTeam1 = gameDoc['score_team1'];
                      int scoreTeam2 = gameDoc['score_team2'];
                      String currentTurn = gameDoc['current_turn'];
                      String currentTurnTeam =
                          (currentTurn == 'team1') ? team1Name : team2Name;

                      return Container(
                        width: 600,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left side: Teams and scores
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$team1Name${currentTurnTeam == team1Name ? "*" : ""}"
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: currentTurnTeam == team1Name
                                            ? Color(0xFF4A148C)
                                            : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "$scoreTeam1",
                                      style: TextStyle(
                                        color: currentTurnTeam == team1Name
                                            ? Color(0xFF4A148C)
                                            : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$team2Name${currentTurnTeam == team2Name ? "*" : ""}"
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: currentTurnTeam == team2Name
                                            ? Color(0xFF4A148C)
                                            : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "$scoreTeam2",
                                      style: TextStyle(
                                        color: currentTurnTeam == team2Name
                                            ? Color(0xFF4A148C)
                                            : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Right side: Countdown timer text
                            Text(
                              "$remainingTime seconds",
                              style: const TextStyle(
                                color: Color(0xFF4A148C),
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: 600,
                    child: Divider(
                      color: Color.fromRGBO(74, 20, 140, .2),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display countdown or round timer
                  if (countdownActive)
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(236, 230, 240, 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      width: 600,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text("Move the screen to your forehead!",
                              style: TextStyle(
                                color: Color(0xFF4A148C),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                          Text(
                            "$countdownValue",
                            style: const TextStyle(
                              color: Color(0xFF4A148C),
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (roundActive)
                    if (roundActive)
                      Container(
                        alignment: Alignment
                            .center, // centers content within the container
                        width: 600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentWord.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF4A148C),
                                fontSize: 58,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // center the buttons in the row
                              children: [
                                ElevatedButton(
                                  onPressed: _skipWord,
                                  child: const Text("Skip",
                                      style: TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: _markWordCorrect,
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all<Color>(
                                            Colors.green),
                                  ),
                                  child: const Text("Correct",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
