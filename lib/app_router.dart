import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:krewe_iq/screens/about_screen.dart';
import 'package:krewe_iq/screens/contact_screen.dart';
import 'package:krewe_iq/screens/head_to_head_gameover.dart';
import 'package:krewe_iq/screens/head_to_head_screen.dart';
import 'package:krewe_iq/screens/head_to_head_setup_screen.dart';
import 'package:krewe_iq/screens/home_screen.dart';
import 'package:krewe_iq/screens/map_screen.dart';
import 'package:krewe_iq/screens/pass_and_play_setup_screen.dart';
import 'package:krewe_iq/screens/payment_screen.dart';
import 'package:krewe_iq/screens/payment_success_screen.dart';
import 'package:krewe_iq/screens/login_screen.dart';
import 'package:krewe_iq/screens/register_screen.dart';
import 'package:krewe_iq/screens/results_screen.dart';
import 'package:krewe_iq/screens/scavenger-hunt-screen.dart';
import 'package:krewe_iq/screens/scavenger_hunt_history_screen.dart';
import 'package:krewe_iq/screens/scavenger_hunt_setup_screen.dart';
import 'package:krewe_iq/screens/trivia_screen.dart';
import 'package:krewe_iq/screens/questions_screen.dart';
import 'package:krewe_iq/screens/krewe_selector_screen.dart';
import 'package:krewe_iq/screens/masks_up_screen.dart';

/// ✅ RouterNotifier (Manages GoRouter state)
class RouterNotifier extends ChangeNotifier {
  RouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}

String getInitialRoute() {
  String initialRoute =
      Uri.base.hasFragment ? Uri.base.fragment : Uri.base.path;
  if (initialRoute.isNotEmpty && !initialRoute.startsWith('/')) {
    initialRoute = '/$initialRoute';
  }
  return initialRoute;
}

/// ✅ GoRouter configuration with deep linking support
GoRouter appRouter(bool isLoggedIn, GlobalKey<NavigatorState> navigatorKey) {
  final routerNotifier = RouterNotifier();

  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: routerNotifier,
    // initialLocation: Uri.base.path.isEmpty ? '/' : Uri.base.path,
    initialLocation: Uri.base.hasFragment ? Uri.base.fragment : Uri.base.path,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeScreen(),
      ),

    GoRoute(
        path: '/map',
        builder: (context, state) => LevelMapPage(),
      ),

      GoRoute(
        path: '/about',
        builder: (context, state) => AboutScreen(),
      ),

      GoRoute(
        path: '/contact',
        builder: (context, state) => ContactScreen(),
      ),

      // ✅ Payment routes
      GoRoute(
        path: '/payment',
        builder: (context, state) =>
            const PaymentScreen(title: 'Krewe IQ Payment'),
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) => PaymentSuccessScreen(),
      ),

      // ✅ Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onTap: () => GoRouter.of(context).go('/register'),
          onContinueAsGuest: () => GoRouter.of(context).go('/home'),
          // onContinueAsGuest: () => GoRouter.of(context).go('/trivia'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(onTap: () {}),
      ),

      // ✅ Trivia routes
      GoRoute(
        path: '/trivia',
        builder: (context, state) => TriviaListScreen(
          onTriviaSelected: (String quizId) {},
          onReturnToHome: () {},
          isUntimed: false,
        ),
      ),

      GoRoute(
        path: '/trivia/untimed',
        builder: (context, state) => TriviaListScreen(
          onTriviaSelected: (String quizId) {},
          onReturnToHome: () {},
          isUntimed: true,
        ),
      ),

      // ✅ Trivia routes
      GoRoute(
        path: '/about',
        builder: (context, state) => AboutScreen(),
      ),

      GoRoute(
        path: '/contact',
        builder: (context, state) => ContactScreen(),
      ),

      GoRoute(
        path: '/scavenger-hunt',
        builder: (context, state) => ScavengerHuntSetupScreen(),
      ),

      // Scavenger Hunt Landing Page (Dynamic Route with Hunt ID)
      GoRoute(
        path: '/scavenger-hunt/play/:huntId',
        builder: (context, state) {
          final huntId = state.pathParameters['huntId']!;
          return ScavengerHuntPage(key: ValueKey(huntId), huntId: huntId);
        },
      ),
      GoRoute(
        path: '/scavenger-hunt/history',
        builder: (context, state) => const ScavengerHuntHistoryPage(),
      ),

      GoRoute(
        path: '/challenge',
        builder: (context, state) => const HeadToHeadSetupScreen(),
      ),
      GoRoute(
        path: '/challenge/play/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          final config = state.extra as Map<String, dynamic>;
          return HeadToHeadGameScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: '/challenge/gameover/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          return GameOverScreen(gameId: gameId);
        },
      ),

      GoRoute(
        path: '/pass-and-play/:level',
        builder: (context, state) {
          final levelParam = state.pathParameters['level']!;
          // Map the level string to a difficulties map.
          Map<String, bool> difficulties;
          if (levelParam == "kids") {
            difficulties = {'isKids': true}; // Flag for kids questions.
          } else if (levelParam == "easy") {
            difficulties = {'easy': true, 'hard': false, 'mix': false};
          } else if (levelParam == "hard") {
            difficulties = {'easy': false, 'hard': true, 'mix': false};
          } else if (levelParam == "mix") {
            difficulties = {'easy': false, 'hard': false, 'mix': true};
          } else {
            difficulties = {'easy': false, 'hard': false, 'mix': false};
          }

          final extra = state.extra as Map<String, dynamic>? ?? {};

          return QuestionsScreen(
            category: "all", // For pass-and-play, we use all categories.
            level: 1, // Not used in this mode.
            isPassAndPlay: true,
            isUntimed: false,
            player1: extra['player1'] ?? "Player 1",
            player2: extra['player2'] ?? "Player 2",
            questionCount: extra['questionCount'] ?? 5,
            timerDuration: extra['timerDuration'] ?? 30,
            difficulties: difficulties,
            passAndPlayDifficulty:
                levelParam, // Pass along the difficulty string.
          );
        },
      ),
      GoRoute(
        path: '/pass-and-play/:level/results',
        builder: (context, state) {
          final levelParam = state.pathParameters['level']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultsScreen(
            isPassAndPlay: true,
            player1Score: extra['player1Score'] ?? 0,
            player2Score: extra['player2Score'] ?? 0,
            player1: extra['player1'] ?? "Player 1",
            player2: extra['player2'] ?? "Player 2",
            timerDuration: extra['timerDuration'] ?? 30,
            isUntimed: false,
            chosenAnswers: [], // not used in pass-and-play mode
            totalScore:
                (extra['player1Score'] ?? 0) + (extra['player2Score'] ?? 0),
            onRestart: () =>
                GoRouter.of(context).go('/pass-and-play/$levelParam'),
            category: "all",
            level: 1,
            initialQuestionCount: extra['questionCount'] ?? 5,
            initialDifficulties: {
              'isKids': extra['isKids'] ?? false,
              'easy': extra['easy'] ?? false,
              'hard': extra['hard'] ?? false,
              'mix': extra['mix'] ?? true,
            },
            passAndPlayDifficulty: levelParam, // <--- add this line
          );
        },
      ),
      GoRoute(
        path: '/trivia/:category/:level',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          final level = int.parse(state.pathParameters['level']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuestionsScreen(
            category: category,
            level: level,
            isUntimed: false,
            timerDuration: extra['timerDuration'] ?? 30,
            isPassAndPlay: extra['isPassAndPlay'] ?? false,
            player1: extra['player1'] ?? "Player 1",
            player2: extra['player2'] ?? "Player 2",
            questionCount: extra['questionCount'] ?? 5,
            difficulties: extra['difficulties'] ??
                {'easy': false, 'hard': false, 'mix': false},
          );
        },
      ),

      GoRoute(
        path: '/untimed/trivia/:category/:level',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          final level = int.parse(state.pathParameters['level']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuestionsScreen(
            category: category,
            level: level,
            isUntimed: true,
            timerDuration: extra['timerDuration'] ?? 30,
            isPassAndPlay: extra['isPassAndPlay'] ?? false,
            player1: extra['player1'] ?? "Player 1",
            player2: extra['player2'] ?? "Player 2",
            questionCount: extra['questionCount'] ?? 5,
            difficulties: extra['difficulties'] ??
                {'easy': false, 'hard': false, 'mix': false},
          );
        },
      ),

      GoRoute(
        path: '/trivia/:category/:level/results',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          final level = int.parse(state.pathParameters['level']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultsScreen(
            timerDuration: extra['timerDuration'] ?? 30,
            chosenAnswers: List<String>.from(extra['chosenAnswers'] ?? []),
            totalScore: extra['totalScore'] ?? 0,
            onRestart: () => GoRouter.of(context).go('/trivia'),
            category: category,
            level: level,
            isUntimed: false,
          );
        },
      ),

      GoRoute(
        path: '/untimed/trivia/:category/:level/results',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          final level = int.parse(state.pathParameters['level']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultsScreen(
            timerDuration: extra['timerDuration'] ?? 30,
            chosenAnswers: List<String>.from(extra['chosenAnswers'] ?? []),
            totalScore: extra['totalScore'] ?? 0,
            onRestart: () => GoRouter.of(context).go('/trivia'),
            category: category,
            level: level,
            isUntimed: true,
          );
        },
      ),

      GoRoute(
        path: '/pass-and-play-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PassAndPlaySetupScreen(
            initialPlayer1Name: extra['player1'] as String?,
            initialPlayer2Name: extra['player2'] as String?,
            initialQuestionCount: extra['questionCount'] as int?,
            initialIsKids: extra['isKids'] as bool?,
            initialEasy: extra['selectedDifficulty'] == "easy",
            initialHard: extra['selectedDifficulty'] == "hard",
            initialMix: extra['selectedDifficulty'] == "mix",
            initialTimerDuration:
                extra['timerDuration'] as int?, // use the same key here
          );
        },
      ),

      // ✅ Krewe Selector routes
      GoRoute(
        path: '/krewe-selector',
        builder: (context, state) => const KreweSelectorScreen(),
      ),

      // ✅ Masks Up routes
      GoRoute(
        path: '/masks-up',
        builder: (context, state) => const MasksUpScreen(),
      ),

      // ✅ Catch-all 404 page
      GoRoute(
        path: '/not-found',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text("Page Not Found")),
          body: const Center(child: Text("Oops! Page does not exist.")),
        ),
      ),
    ],

    // ✅ Global redirect callback
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      // If the user is trying to access the root or login screen, decide where to send them.
      if (state.uri.path == "/" || state.uri.path == "/login") {
        return user == null ? "/login" : "/home";
        // return user == null ? "/login" : "/trivia";
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text("Page Not Found")),
      body: const Center(child: Text("Oops! Page does not exist.")),
    ),
  );
}
