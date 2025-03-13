import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class ResultsScreen extends StatefulWidget {
  // Standard quiz fields:
  final List<String> chosenAnswers;
  final int totalScore;
  final VoidCallback onRestart;
  final String category;
  final int level;
  // New fields for pass-and-play mode:
  final bool isPassAndPlay;
  final int? player1Score;
  final int? player2Score;
  final String? player1;
  final String? player2;
  // New optional fields for retaining setup values:
  final int? initialQuestionCount;
  final Map<String, bool>? initialDifficulties;
  // New field to retain the difficulty string.
  final String? passAndPlayDifficulty;
  final bool isUntimed;

  final dynamic timerDuration;

  const ResultsScreen({
    super.key,
    required this.chosenAnswers,
    required this.totalScore,
    required this.onRestart,
    required this.category,
    required this.level,
    required this.isUntimed,
    required this.timerDuration,
    this.isPassAndPlay = false,
    this.player1Score,
    this.player2Score,
    this.player1,
    this.player2,
    this.initialQuestionCount,
    this.initialDifficulties,
    this.passAndPlayDifficulty,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _highestScore = 0;
  bool _hasNewHighScore = false;
  String? _nextCategory;
  int? _nextLevel;
  int _maxPossibleScore = 0;
  int _totalUserScore = 0;
  int _timerDuration = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isPassAndPlay) {
      _saveAndFetchScores();
      _fetchTotalUserScore();
    }
    _computeNextQuiz();
  }

  void _saveAndFetchScores() async {
    // First, get the previous high score.
    int previousHighScore = await _firestoreService.getHighestScore(
      widget.category,
      widget.level,
      isUntimed: widget.isUntimed,
    );

    // Set flag if the current total score beats the previous score.
    _hasNewHighScore = widget.totalScore > previousHighScore;

    // Now save the score (this will update the stored high score if needed).
    await _firestoreService.saveQuizScore(
      widget.category,
      widget.level,
      widget.totalScore,
      isUntimed: widget.isUntimed,
    );

    // Delay slightly then fetch the updated high score.
    await Future.delayed(const Duration(milliseconds: 500));
    int fetchedHighScore = await _firestoreService.getHighestScore(
      widget.category,
      widget.level,
      isUntimed: widget.isUntimed,
    );
    setState(() {
      _highestScore = fetchedHighScore;
    });
  }

  Future<void> _computeNextQuiz() async {
    List<String> categories = await _firestoreService.fetchCategories();
    int currentIndex = categories.indexOf(widget.category);
    List<int> levels =
        await _firestoreService.fetchAvailableLevels(widget.category);
    levels.sort();

    String nextCategory;
    int nextLevel;

    List<int> higherLevels = levels.where((lvl) => lvl > widget.level).toList();
    if (higherLevels.isNotEmpty) {
      nextCategory = widget.category;
      nextLevel = higherLevels.first;
    } else {
      nextLevel = 1;
      if (currentIndex < categories.length - 1) {
        nextCategory = categories[currentIndex + 1];
      } else {
        nextCategory = categories.first;
      }
    }
    setState(() {
      _nextCategory = nextCategory;
      _nextLevel = nextLevel;
    });
  }

  void _fetchTotalUserScore() async {
    int? questionCount = await _firestoreService.fetchQuestionCount(
      widget.category,
      widget.level,
    );

    setState(() {
      // _totalUserScore = scores['totalScore']!;
      _maxPossibleScore =
          widget.isUntimed ? questionCount! : questionCount! * 5;
    });
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildStandardResults(BuildContext context) {
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final double overallRating =
        _maxPossibleScore > 0 ? (widget.totalScore / _maxPossibleScore * 5) : 0;
    final double overallHighScoreRating =
        _maxPossibleScore > 0 ? (_highestScore / _maxPossibleScore * 5) : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header Section:
        if (_hasNewHighScore && isLoggedIn) ...[
          Image.asset(
            'images/newhighscore.png',
            width: 400,
          ),
          const SizedBox(height: 10),
          const Text(
            "Quiz Completed!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ] else ...[
          Image.asset(
            'images/quizcompleted.png',
            width: 400,
          ),
        ],
        const SizedBox(height: 20),

        const SizedBox(height: 20),
        // Display scores row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text(
                  "TOTAL SCORE",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${widget.totalScore} pts",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RatingBarIndicator(
                  rating: overallRating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20.0,
                  direction: Axis.horizontal,
                ),
              ],
            ),
            const SizedBox(width: 40),
            if (_highestScore > 0)
              Column(
                children: [
                  const Text(
                    "HIGHEST SCORE",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$_highestScore pts",
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RatingBarIndicator(
                    rating: overallHighScoreRating,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                ],
              ),
          ],
        ),
        // Next Quiz section remains unchanged...
        if (widget.category.toLowerCase() != "sample" &&
            _nextCategory != null &&
            _nextLevel != null)
          Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "Next Quiz: ${_formatCategory(_nextCategory!)}, Level $_nextLevel",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  String nextRoute = widget.isUntimed
                      ? '/untimed/trivia/$_nextCategory/$_nextLevel'
                      : '/trivia/$_nextCategory/$_nextLevel';
                  GoRouter.of(context).go(nextRoute);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  "Start Next Quiz",
                  style: TextStyle(color: Color(0xFF4A148C)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        OutlinedButton(
          onPressed: () {
            String route = widget.isUntimed ? '/trivia/untimed' : '/trivia';
            GoRouter.of(context).go(route);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: const BorderSide(color: Colors.white),
            textStyle: const TextStyle(color: Colors.white),
          ),
          child: const Text(
            "Back to All Trivia",
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPassAndPlayResults(BuildContext context) {
    String winnerText = "";
    if (widget.player1Score != null &&
        widget.player2Score != null &&
        widget.player1 != null &&
        widget.player2 != null) {
      if (widget.player1Score! > widget.player2Score!) {
        winnerText = "${widget.player1} Wins!";
      } else if (widget.player2Score! > widget.player1Score!) {
        winnerText = "${widget.player2} Wins!";
      } else {
        winnerText = "It's a Tie!";
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'images/trophy.png',
          height: 300,
        ),
        Text(
          winnerText,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  widget.player1 ?? "Player 1",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${widget.player1Score ?? 0} pts",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 40),
            Column(
              children: [
                Text(
                  widget.player2 ?? "Player 2",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "${widget.player2Score ?? 0} pts",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            String difficulty = widget.passAndPlayDifficulty ?? "mix";
            Map<String, dynamic> extras = {
              'player1': widget.player1,
              'player2': widget.player2,
              'questionCount': widget.initialQuestionCount ?? 5,
              'selectedDifficulty': widget.passAndPlayDifficulty ?? "mix",
              'isKids': (widget.passAndPlayDifficulty ?? "mix") == "kids",
              'timerDuration': widget.timerDuration,
            };
            GoRouter.of(context).go('/pass-and-play-setup', extra: extras);
          },
          child: const Text(
            "Play Again",
            style: TextStyle(color: Color(0xFF4A148C)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            GoRouter.of(context).go('/home');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            backgroundColor: Colors.white,
          ),
          child: const Text(
            "Home",
            style: TextStyle(color: Color(0xFF4A148C)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: widget.isPassAndPlay
                ? _buildPassAndPlayResults(context)
                : _buildStandardResults(context),
          ),
        ),
      ),
    );
  }
}
