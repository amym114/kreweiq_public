import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/answer_button.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/components/score_stats.dart';
import 'package:krewe_iq/components/scoreboard.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({
    super.key,
    required this.category,
    required this.level,
    required this.isUntimed,
    required this.timerDuration,
    this.isPassAndPlay = false,
    this.player1 = "Player 1",
    this.player2 = "Player 2",
    this.questionCount = 5,
    this.difficulties,
    this.passAndPlayDifficulty,
  });

  final String category;
  final int level;
  final bool isPassAndPlay;
  final String player1;
  final String player2;
  final int questionCount;
  final Map<String, bool>? difficulties;
  final String? passAndPlayDifficulty;
  final bool isUntimed;
  final int timerDuration;

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _questions = [];
  List<String> _shuffledAnswers = [];
  bool _isLoading = true;
  int currentQuestionIndex = 0;
  Timer? _timer;
  double _elapsedTime = 0.0; // used only for timed mode
  int _score = 5; // max points available per question in timed mode
  int _totalScore = 0; // aggregated score for timed mode
  int _player1Score = 0;
  int _player2Score = 0;
  bool _isAnswerSelected = false;
  bool _stopTimer = false;
  bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

  // Track player's turn for pass-and-play mode.
  bool isPlayer1Turn = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    // Start the timer only in timed mode.
    if (!widget.isUntimed) {
      _startCountdownTimer();
    }
  }

  /// Fetch questions for the given category and level.
  void _fetchQuestions() async {
    if (widget.isPassAndPlay) {
      int desiredCount = widget.questionCount;
      final Map<String, bool> diffs =
          widget.difficulties ?? {'easy': false, 'hard': false, 'mix': false};
      bool isKids = (widget.passAndPlayDifficulty == "kids");
      bool isSample = (widget.passAndPlayDifficulty == "sample");

      List<Map<String, dynamic>> fetchedQuestions =
          await _firestoreService.fetchQuestionsByDifficulty(
        easy: diffs['easy'] ?? false,
        hard: diffs['hard'] ?? false,
        mix: diffs['mix'] ?? false,
        count: widget.questionCount,
        isDemo: !isLoggedIn,
        isKids: isKids,
        isSample: isSample,
      );

      if (fetchedQuestions.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("No Questions Found"),
            content: const Text(
                "There are no questions available for the selected settings."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      if (fetchedQuestions.length < desiredCount * 2) {
        desiredCount = fetchedQuestions.length ~/ 2;
      }

      List<Map<String, dynamic>> player1Questions =
          fetchedQuestions.take(desiredCount).toList();
      List<Map<String, dynamic>> player2Questions =
          fetchedQuestions.skip(desiredCount).take(desiredCount).toList();
      List<Map<String, dynamic>> interleavedQuestions = [];
      for (int i = 0; i < desiredCount; i++) {
        interleavedQuestions.add(player1Questions[i]);
        interleavedQuestions.add(player2Questions[i]);
      }

      setState(() {
        _questions = interleavedQuestions;
        _isLoading = false;
        _shuffleCurrentAnswers();
      });
      // For pass-and-play mode, you might still want the timer.
      if (!widget.isUntimed) {
        _startCountdownTimer();
      }
    } else {
      List<Map<String, dynamic>> fetchedQuestions =
          await _firestoreService.fetchQuestionsByCategoryAndLevel(
        widget.category,
        widget.level,
        isDemo: !isLoggedIn,
      );
      setState(() {
        _questions = fetchedQuestions;
        _isLoading = false;
        _shuffleCurrentAnswers();
      });
      if (!widget.isUntimed) {
        _startCountdownTimer();
      }
    }
  }

  /// Shuffle answers for the current question.
  void _shuffleCurrentAnswers() {
    if (_questions.isNotEmpty) {
      List<String> answers =
          List<String>.from(_questions[currentQuestionIndex]['answers']);
      answers.shuffle();
      setState(() {
        _shuffledAnswers = answers;
      });
    }
  }

  /// For timed mode, start the countdown timer.
  void _startCountdownTimer() {
    _elapsedTime = 0.0;
    _score = 5;
    _timer?.cancel();
    final double totalDuration = widget.timerDuration.toDouble();
    final double deductionInterval =
        totalDuration / 5; // each star lost per this interval

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _elapsedTime += 0.05;
        _score = 5 - ((_elapsedTime / deductionInterval).floor());
        if (_score < 0) _score = 0;
      });
      if (_elapsedTime >= totalDuration) {
        _timer?.cancel();
        if (!_isAnswerSelected) {
          _isAnswerSelected = true;
          setState(() {
            _stopTimer = true;
          });
          _showScorePopup(false, '');
        }
      }
    });
  }

  /// Handles answer selection.
  void answerQuestion(String selectedAnswer) {
    if (_isAnswerSelected) return;
    _isAnswerSelected = true;
    _timer?.cancel();

    bool isCorrect =
        _questions[currentQuestionIndex]['correct_answer'] == selectedAnswer;
    // Use simple scoring (1 point per correct answer) when untimed.
    int finalScore =
        widget.isUntimed ? (isCorrect ? 1 : 0) : (isCorrect ? _score : 0);

    if (isCorrect) {
      if (widget.isPassAndPlay) {
        if (isPlayer1Turn) {
          setState(() {
            _player1Score += finalScore;
          });
        } else {
          setState(() {
            _player2Score += finalScore;
          });
        }
      } else {
        setState(() {
          _totalScore += finalScore;
        });
      }
    }

    _showScorePopup(isCorrect, selectedAnswer);
  }

  /// Displays the score popup for the current question.
  void _showScorePopup(bool isCorrect, String selectedAnswer) {
    setState(() {
      _stopTimer = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isCorrect
                      ? "images/correct-new.jpg"
                      : "images/missedit-new.jpg",
                  width: 350,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: widget.isUntimed
                      // Simple feedback for untimed (simple scoring)
                      ? Text(
                          isCorrect
                              ? "Correct!"
                              : "Incorrect. The correct answer is: ${_questions[currentQuestionIndex]['correct_answer']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        )
                      // For timed mode, show detailed feedback.
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCorrect)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Well done! You scored",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      return index < _score
                                          ? const Icon(Icons.star,
                                              color: Colors.amber)
                                          : const Icon(Icons.star_border,
                                              color: Colors.amber);
                                    }),
                                  ),
                                ],
                              )
                            else
                              Text(
                                "Correct Answer: ${_questions[currentQuestionIndex]['correct_answer']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Move to next question or finish quiz.
                if (currentQuestionIndex < _questions.length - 1) {
                  setState(() {
                    currentQuestionIndex++;
                    _isAnswerSelected = false;
                    _stopTimer = false;
                    _elapsedTime = 0.0;
                  });
                  if (widget.isPassAndPlay) {
                    setState(() {
                      isPlayer1Turn = !isPlayer1Turn;
                    });
                  }
                  _shuffleCurrentAnswers();
                  if (!widget.isUntimed) {
                    _startCountdownTimer();
                  }
                } else {
                  // End of quiz: navigate to results screen.
                  if (widget.isPassAndPlay) {
                    Map<String, dynamic> extras = {
                      'player1Score': _player1Score,
                      'player2Score': _player2Score,
                      'player1': widget.player1,
                      'player2': widget.player2,
                      'questionCount': widget.questionCount,
                      'reallyEasy': widget.difficulties?['reallyEasy'] ?? false,
                      'easy': widget.difficulties?['easy'] ?? false,
                      'hard': widget.difficulties?['hard'] ?? false,
                      'mix': widget.difficulties?['mix'] ?? true,
                      'passAndPlayDifficulty':
                          widget.passAndPlayDifficulty ?? "easy",
                      'timerDuration': widget.timerDuration,
                    };
                    GoRouter.of(context).go(
                      '/pass-and-play/${widget.passAndPlayDifficulty ?? "easy"}/results',
                      extra: extras,
                    );
                  } else {
                    Map<String, dynamic> extras = {
                      'totalScore': _totalScore,
                      'chosenAnswers':
                          _questions.map((q) => q['question']).toList(),
                    };
                    String nextRoute = widget.isUntimed
                        ? '/untimed/trivia/${widget.category}/${widget.level}/results'
                        : '/trivia/${widget.category}/${widget.level}/results';
                    GoRouter.of(context).go(nextRoute, extra: extras);
                  }
                }
              },
              child: widget.isPassAndPlay
                  ? Text(
                      "Next Up: ${isPlayer1Turn ? widget.player2 : widget.player1}")
                  : const Text("Next"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double remainingFraction =
        (_elapsedTime / widget.timerDuration).clamp(0.0, 1.0);
    remainingFraction = 1.0 - remainingFraction;
    const double topStickyHeight = 70.0;
    const double bottomStickyHeight = 60.0;

    final int displayQuestionNumber = widget.isPassAndPlay
        ? (currentQuestionIndex ~/ 2)
        : (currentQuestionIndex + 1);
    final int displayTotalQuestions =
        widget.isPassAndPlay ? widget.questionCount : _questions.length;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: widget.isUntimed ? 0 : topStickyHeight,
                        bottom: widget.isUntimed ? 0 : bottomStickyHeight,
                      ),
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 976),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                            ),
                            width: MediaQuery.of(context).size.width,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                _questions[currentQuestionIndex]["question"],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: _shuffledAnswers.map((answer) {
                              return AnswerButton(
                                text: answer,
                                onTap: () {
                                  answerQuestion(answer);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  if (!widget.isUntimed)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Scoreboard(
                        key: const ValueKey('scoreboard'),
                        currentQuestionIndex: displayQuestionNumber,
                        totalQuestions: displayTotalQuestions,
                        totalScore: widget.isPassAndPlay
                            ? (_player1Score + _player2Score)
                            : _totalScore,
                        category: widget.category,
                        level: widget.level,
                        currentQuestionPoints: _score,
                        remainingFraction: remainingFraction,
                        playerTurn: widget.isPassAndPlay
                            ? "${isPlayer1Turn ? widget.player1 : widget.player2}'s Turn"
                            : '',
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ScoreStats(
                      currentQuestionIndex: displayQuestionNumber,
                      totalQuestions: displayTotalQuestions,
                      player1Score: _player1Score,
                      player2Score: _player2Score,
                      player1: widget.player1,
                      player2: widget.player2,
                      isPassAndPlay: widget.isPassAndPlay,
                      totalScore: _totalScore,
                      level: widget.level,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
