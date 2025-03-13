import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class HeadToHeadSetupScreen extends StatefulWidget {
  final String? initialTeam1Name;
  final String? initialTeam2Name;
  final int? initialWordsPerTeam;
  final int? initialTimerDuration;
  final int? initialRounds;
  final String? initialDifficulty; // "easy", "hard", or "sample"

  const HeadToHeadSetupScreen({
    Key? key,
    this.initialTeam1Name,
    this.initialTeam2Name,
    this.initialWordsPerTeam,
    this.initialTimerDuration,
    this.initialRounds,
    this.initialDifficulty,
  }) : super(key: key);

  @override
  _HeadToHeadSetupScreenState createState() => _HeadToHeadSetupScreenState();
}

class _HeadToHeadSetupScreenState extends State<HeadToHeadSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late String team1Name;
  late String team2Name;
  late int wordsPerTeam;
  late int timerDuration;
  late int rounds;
  late String selectedDifficulty; // "easy", "hard", or "sample"

  // Tracks whether the user has purchased (premium).
  bool _hasPurchased = false;

  @override
  void initState() {
    super.initState();
    team1Name = widget.initialTeam1Name ?? 'Team 1';
    team2Name = widget.initialTeam2Name ?? 'Team 2';
    wordsPerTeam = widget.initialWordsPerTeam ?? 5;
    timerDuration = widget.initialTimerDuration ?? 30;
    rounds = widget.initialRounds ?? 1;
    // Set default; this may be adjusted based on purchase status.
    selectedDifficulty = _hasPurchased
        ? widget.initialDifficulty ?? 'easy'
        : widget.initialDifficulty ?? 'sample';
    _fetchPurchaseStatus();
  }

  // Listen to the customer's document to determine purchase status.
  void _fetchPurchaseStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['hasPurchased'] == true) {
        setState(() {
          _hasPurchased = true;
          // If the current selection is "sample" but the user is premium, switch to a free option.
          if (selectedDifficulty == 'sample') {
            selectedDifficulty = 'easy';
          }
        });
      } else {
        setState(() {
          _hasPurchased = false;
          // Force non-premium users to use "sample".
          selectedDifficulty = 'sample';
        });
      }
    });
  }

  void showInstructionsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Play"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Setup",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Each team picks one guesser; everyone else gives clues.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text(
                "Game Play",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    const TextSpan(text: "(1) Click "),
                    TextSpan(
                        text: "Start Game",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                            ". The guesser should hold the phone to their forehead."),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    const TextSpan(
                        text:
                            "(2) When the guesser gets the word right, lower the phone and tap "),
                    TextSpan(
                        text: "Correct",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text:
                            ". If the team thinks the word is too hard, lower the phone and tap "),
                    TextSpan(
                        text: "Skip",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "(3) When the timer runs out, pass the phone to the other team.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                "The game alternates turns until all rounds are completed. The team with the highest score wins.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                "Enjoy the challenge and let the good times roll!",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image and game description.
                  Row(
                    children: [
                      Image.asset("images/head-to-head-2-sm.png"),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mardi Gras Head-to-Head",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Head-to-Head is a competitive \"Guess the Word\" challenge designed for two teams.",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => showInstructionsPopup(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A148C),
                              ),
                              child: const Text(
                                "How to Play",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Form container.
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Team Names.
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: team1Name,
                                  decoration: const InputDecoration(
                                    labelText: 'Team 1 Name',
                                  ),
                                  onChanged: (value) => team1Name = value,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  initialValue: team2Name,
                                  decoration: const InputDecoration(
                                    labelText: 'Team 2 Name',
                                  ),
                                  onChanged: (value) => team2Name = value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Timer Duration.
                          DropdownButtonFormField<int>(
                            value: timerDuration,
                            decoration: const InputDecoration(
                              labelText: 'Seconds per Turn',
                            ),
                            items: [15, 30, 45, 60, 75, 90, 105, 120]
                                .map((sec) => DropdownMenuItem<int>(
                                      value: sec,
                                      child: Text('$sec seconds'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  timerDuration = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          // Number of Rounds.
                          DropdownButtonFormField<int>(
                            value: rounds,
                            decoration: const InputDecoration(
                              labelText: 'Turns per Team',
                            ),
                            items: List.generate(5, (index) => index + 1)
                                .map((number) => DropdownMenuItem<int>(
                                      value: number,
                                      child: Text(number.toString()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  rounds = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          // Difficulty Selection.
                          const Text(
                            "Select Difficulty:",
                            style: TextStyle(fontSize: 12),
                          ),
                          if (_hasPurchased) ...[
                            // Premium users: enable free options; disable Sample.
                            RadioListTile<String>(
                              title: const Text("Easy"),
                              value: "easy",
                              groupValue: selectedDifficulty,
                              onChanged: (val) {
                                setState(() {
                                  selectedDifficulty = val!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text("Hard"),
                              value: "hard",
                              groupValue: selectedDifficulty,
                              onChanged: (val) {
                                setState(() {
                                  selectedDifficulty = val!;
                                });
                              },
                            ),
                          ] else ...[
                            // Non-premium users: enable Sample; disable free options.
                            RadioListTile<String>(
                              title: const Text("Easy"),
                              value: "easy",
                              groupValue: selectedDifficulty,
                              onChanged: null,
                            ),
                            RadioListTile<String>(
                              title: const Text("Hard"),
                              value: "hard",
                              groupValue: selectedDifficulty,
                              onChanged: null,
                            ),
                            RadioListTile<String>(
                              title: const Text("Sample"),
                              value: "sample",
                              groupValue: selectedDifficulty,
                              onChanged: (val) {
                                setState(() {
                                  selectedDifficulty = val!;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Start Game Button.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A148C),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  // Gather configuration data.
                                  Map<String, dynamic> config = {
                                    'team1Name': team1Name,
                                    'team2Name': team2Name,
                                    'wordsPerTeam': wordsPerTeam,
                                    'timerDuration': timerDuration,
                                    'rounds': rounds,
                                    'difficulty': selectedDifficulty,
                                  };

                                  // Create an instance of your Firestore service.
                                  final firestoreService = FirestoreService();

                                  // Create the game and fetch its ID.
                                  String gameId =
                                      await firestoreService.createGame(
                                    team1Name: team1Name,
                                    team2Name: team2Name,
                                    wordsPerTeam: wordsPerTeam,
                                    difficulty: selectedDifficulty,
                                    secondsPerTurn: timerDuration,
                                    rounds: rounds,
                                  );

                                  if (gameId.isNotEmpty) {
                                    // Navigate to the challenge play screen with the generated gameId.
                                    GoRouter.of(context).go(
                                        '/challenge/play/$gameId',
                                        extra: config);
                                  } else {
                                    // Handle error.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Failed to create game. Please try again.'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Start Game',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
