import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:krewe_iq/screens/home_screen.dart';
import 'package:krewe_iq/screens/krewe_selector_screen.dart';
import 'package:krewe_iq/screens/questions_screen.dart';
import 'package:krewe_iq/screens/results_screen.dart';
import 'package:krewe_iq/screens/trivia_screen.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class ScreenContainer extends StatefulWidget {
  const ScreenContainer({super.key});

  @override
  State<ScreenContainer> createState() => _ScreenContainerState();
}

class _ScreenContainerState extends State<ScreenContainer> {
  final FirestoreService _firestoreService = FirestoreService();
  final user = FirebaseAuth.instance.currentUser!;

  List<String> selectedAnswers = [];
  String activeScreen = 'home-screen'; // ✅ Start on Home
  int totalScore = 0;
  int totalQuestions = 0;
  int highestScore = 0;
  String selectedQuizId = "";

  void restartScreenContainer() {
    setState(() {
      selectedAnswers = [];
      totalScore = 0;
      activeScreen = 'home-screen'; // ✅ Back to Home
    });
  }

  void chooseAnswer(String answer, int score) {
    if (answer != "Finished") {
      selectedAnswers.add(answer);
      totalScore += score;
    }

    if (selectedAnswers.length >= totalQuestions) {
      setState(() {
        activeScreen = 'results-screen';
      });
    }
  }

  void goToTriviaList() {
    setState(() {
      activeScreen = 'trivia-list';
    });
  }

  void goToHomeScreen() {
    setState(() {
      activeScreen = 'home-screen'; // ✅ Go to Home Screen
    });
  }

  void goToKreweSelector() {
    setState(() {
      activeScreen = 'krewe-selector';
    });
  }

  void goToMasksUp() {
    setState(() {
      activeScreen = 'masks-up';
    });
  }

  void startTriviaQuiz(String quizId) async {
    setState(() {
      selectedQuizId = quizId;
    });

    int count = await _firestoreService.getTotalQuestions(quizId);

    setState(() {
      totalQuestions = count;
      activeScreen = 'questions-screen';
    });

  }

  @override
  Widget build(BuildContext context) {
    print("🔥 Current Active Screen: $activeScreen");

    Widget screenWidget;

    if (activeScreen == 'home-screen') {
      screenWidget = HomeScreen(
        onTriviaSelected: goToTriviaList, onKreweSelectorSelected: () {  }, onMasksUpSelected: () {  }, onTap: () {  },
         // ✅ Navigate to Trivia List
      );
    } else if (activeScreen == 'trivia-list') {
      screenWidget = TriviaListScreen(
        onTriviaSelected: startTriviaQuiz,
        onReturnToHome: goToHomeScreen, // ✅ Pass function to return home
      );
    } else if (activeScreen == 'questions-screen') {
      screenWidget = QuestionsScreen(
        onSelectAnswer: chooseAnswer,
        quizId: selectedQuizId,
        onReturnToTrivia: goToTriviaList,
      );
    } else if (activeScreen == 'results-screen') {
      screenWidget = ResultsScreen(
        chosenAnswers: selectedAnswers,
        totalScore: totalScore,
        highestScore: highestScore,
        onRestart: restartScreenContainer,
        quizId: selectedQuizId,
      );
    } else if (activeScreen == 'krewe-selector') {
      screenWidget = KreweSelectorScreen();
    }
     else {
      screenWidget = HomeScreen(
        onTriviaSelected: goToTriviaList, onKreweSelectorSelected: () {  }, onMasksUpSelected: () {  }, onTap: () {  },
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9D00CC),
              Color(0xFF791E94),
            ],
          ),
        ),
        child: screenWidget,
      ),
    );
  }
}
