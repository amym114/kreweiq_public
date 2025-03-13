import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches available categories (document names in `trivia`)
  Future<List<String>> fetchCategories() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('trivia')
          .orderBy('sortOrder', descending: false)
          .get();
      List<String> categories = snapshot.docs.map((doc) => doc.id).toList();
      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Fetches questions from `trivia/{category}/questions`
  Future<List<Map<String, dynamic>>> fetchQuestionsByCategoryAndLevel(
    String category,
    int level, {
    bool isDemo = false,
  }) async {
    try {
      QuerySnapshot questionsSnapshot = await _db
          .collection('trivia')
          .doc(category)
          .collection('questions')
          .where('level', isEqualTo: level)
          .get();

      if (questionsSnapshot.docs.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> filteredQuestions = questionsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (isDemo && (!data.containsKey('demo') || data['demo'] != true)) {
              return null;
            }
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
              'demo': data['demo'],
            };
          })
          .where((q) => q != null)
          .cast<Map<String, dynamic>>()
          .toList();

      return filteredQuestions;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuestionsByDifficulty({
    required bool easy,
    required bool hard,
    required bool mix,
    required int count, // count per player
    bool isDemo = false,
    bool isKids = false, // if true, use kids questions collection.
    bool isSample = false, // if true, use sample questions.
  }) async {
    try {
      List<Map<String, dynamic>> questions = [];
      if (isSample) {
        QuerySnapshot sampleSnapshot = await _db
            .collection('trivia')
            .doc("sample")
            .collection('questions')
            .get();
        List<Map<String, dynamic>> sampleQuestions =
            sampleSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'question': data['question'],
            'answers': List<String>.from(data['options']),
            'correct_answer': data['answer'],
          };
        }).toList();
        sampleQuestions.shuffle();
        return sampleQuestions.length < count * 2
            ? sampleQuestions.take(sampleQuestions.length).toList()
            : sampleQuestions.take(count * 2).toList();
      } else if (isKids) {
        QuerySnapshot kidsSnapshot = await _db
            .collection('trivia')
            .doc("just_for_kids")
            .collection('questions')
            .get();
        List<Map<String, dynamic>> kidsQuestions = kidsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'question': data['question'],
            'answers': List<String>.from(data['options']),
            'correct_answer': data['answer'],
          };
        }).toList();
        kidsQuestions.shuffle();
        return kidsQuestions.length < count * 2
            ? kidsQuestions.take(kidsQuestions.length).toList()
            : kidsQuestions.take(count * 2).toList();
      } else {
        if (mix) {
          QuerySnapshot easySnapshot = await _db
              .collectionGroup('questions')
              .where('level', isEqualTo: 1)
              .where('forKids', isEqualTo: false)
              .where('forMobile', isEqualTo: false)
              .get();
          QuerySnapshot hardSnapshot = await _db
              .collectionGroup('questions')
              .where('level', isGreaterThanOrEqualTo: 2)
              .where('forKids', isEqualTo: false)
              .where('forMobile', isEqualTo: false)
              .get();
          List<Map<String, dynamic>> easyQuestions =
              easySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
            };
          }).toList();
          List<Map<String, dynamic>> hardQuestions =
              hardSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
            };
          }).toList();
          questions = [...easyQuestions, ...hardQuestions];
        } else if (easy) {
          QuerySnapshot snapshot = await _db
              .collectionGroup('questions')
              .where('forKids', isEqualTo: false)
              .where('forMobile', isEqualTo: false)
              .where('level', isEqualTo: 1)
              .get();
          questions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
            };
          }).toList();
        } else if (hard) {
          QuerySnapshot snapshot = await _db
              .collectionGroup('questions')
              .where('level', isGreaterThanOrEqualTo: 2)
              .where('forKids', isEqualTo: false)
              .where('forMobile', isEqualTo: false)
              .get();
          questions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
            };
          }).toList();
        } else {
          QuerySnapshot snapshot = await _db
              .collectionGroup('questions')
              .where('level', isEqualTo: 1)
              .where('forKids', isEqualTo: false)
              .where('forMobile', isEqualTo: false)
              .get();
          questions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'question': data['question'],
              'answers': List<String>.from(data['options']),
              'correct_answer': data['answer'],
              'level': data['level'],
            };
          }).toList();
        }
        questions.shuffle();
        return questions.length < count * 2
            ? questions.take(questions.length).toList()
            : questions.take(count * 2).toList();
      }
    } catch (e) {
      return [];
    }
  }

  Future<int?> fetchQuestionCount(String category, int level) async {
    try {
      final query = _db
          .collection('trivia')
          .doc(category)
          .collection('questions')
          .where('level', isEqualTo: level);
      final countSnapshot = await query.count().get();
      return countSnapshot.count;
    } catch (e) {
      return 0;
    }
  }

  /// Fetches distinct levels for a given category.
  Future<List<int>> fetchAvailableLevels(String category) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('trivia')
          .doc(category)
          .collection('questions')
          .get();
      Set<int> levels = snapshot.docs.map((doc) => doc['level'] as int).toSet();
      List<int> sortedLevels = levels.toList()..sort();
      return sortedLevels;
    } catch (e) {
      return [];
    }
  }

  /// Saves or updates the user's quiz score in the `trivia_scores` collection.
  /// In untimed mode, values are saved to the new untimed fields.
  Future<int> saveQuizScore(
    String category,
    int level,
    int totalScore, {
    bool isUntimed = false,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      String userId = user.uid;
      String quizId = "${category}_level_$level";

      DocumentReference userScoreRef =
          _db.collection('trivia_scores').doc(userId);
      DocumentReference quizScoreRef =
          userScoreRef.collection('scores').doc(quizId);

      DocumentSnapshot quizSnapshot = await quizScoreRef.get();
      final data = quizSnapshot.data() as Map<String, dynamic>? ?? {};
      print("Existing data for $quizId: $data");

      int highestScore = isUntimed
          ? (data['highest_score_untimed'] ?? 0)
          : (data['highest_score'] ?? 0);
      int newHighestScore =
          totalScore > highestScore ? totalScore : highestScore;

      print(
          "Saving score for $quizId. totalScore: $totalScore, previous highest: $highestScore, new highest: $newHighestScore");

      if (isUntimed) {
        await quizScoreRef.set({
          'latest_score_untimed': totalScore,
          'highest_score_untimed': newHighestScore,
          'highest_score_date_untimed': newHighestScore > highestScore
              ? FieldValue.serverTimestamp()
              : data['highest_score_date_untimed'],
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await quizScoreRef.set({
          'latest_score': totalScore,
          'highest_score': newHighestScore,
          'highest_score_date': newHighestScore > highestScore
              ? FieldValue.serverTimestamp()
              : data['highest_score_date'],
          'last_played': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return newHighestScore;
    } catch (e) {
      return 0;
    }
  }

  /// Fetches the highest score for a specific category and level.
  /// Uses untimed fields if [isUntimed] is true.
  Future<int> getHighestScore(String category, int level,
      {bool isUntimed = false}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      String userId = user.uid;
      String quizId = "${category}_level_$level";
      DocumentSnapshot quizSnapshot = await _db
          .collection('trivia_scores')
          .doc(userId)
          .collection('scores')
          .doc(quizId)
          .get();
      if (quizSnapshot.exists) {
        final data = quizSnapshot.data() as Map<String, dynamic>? ?? {};
        // print("Fetched data for $quizId: $data");
        int highestScore = isUntimed
            ? (data['highest_score_untimed'] ?? 0)
            : (data['highest_score'] ?? 0);
        return highestScore;
      } else {
        // print("No document exists for $quizId");
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Fetches category scores.
  /// For untimed mode, each question is worth 1 point; for timed mode, each is worth 5.
  Future<Map<String, Map<String, int>>> fetchCategoryScores(
      {bool isUntimed = false}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};
      String userId = user.uid;
      QuerySnapshot userScoresSnapshot = await _db
          .collection('trivia_scores')
          .doc(userId)
          .collection('scores')
          .get();

      Map<String, int> userCategoryScores = {};
      for (var doc in userScoresSnapshot.docs) {
        String quizId = doc.id;
        // Safely cast the document data.
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
        int score = isUntimed
            ? (data.containsKey('highest_score_untimed')
                ? data['highest_score_untimed'] as int
                : 0)
            : (data.containsKey('highest_score')
                ? data['highest_score'] as int
                : 0);
        String category = quizId.split('_level_')[0];
        userCategoryScores.update(category, (value) => value + score,
            ifAbsent: () => score);
      }

      QuerySnapshot categoriesSnapshot = await _db.collection('trivia').get();

      List<Future<MapEntry<String, Map<String, int>>>> categoryFutures =
          categoriesSnapshot.docs.map((categoryDoc) async {
        String category = categoryDoc.id;
        QuerySnapshot questionSnapshot = await _db
            .collection('trivia')
            .doc(category)
            .collection('questions')
            .get();
        int multiplier = isUntimed ? 1 : 5;
        int totalPossibleScore = questionSnapshot.size * multiplier;
        return MapEntry(category, {
          'earnedScore': userCategoryScores[category] ?? 0,
          'maxPossibleScore': totalPossibleScore,
        });
      }).toList();

      List<MapEntry<String, Map<String, int>>> categoryEntries =
          await Future.wait(categoryFutures);
      Map<String, Map<String, int>> categoryScores =
          Map.fromEntries(categoryEntries);
      return categoryScores;
    } catch (e) {
      return {};
    }
  }

  /// Fetches the total user score across all quizzes.
  /// Uses untimed fields if [isUntimed] is true.
  Future<Map<String, int>> fetchTotalUserScore({bool isUntimed = false}) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'totalScore': 0, 'maxPossibleScore': 0};
      }
      String userId = user.uid;

      var userScoresFuture = _db
          .collection('trivia_scores')
          .doc(userId)
          .collection('scores')
          .get();
      var categoriesFuture = _db.collection('trivia').get();

      QuerySnapshot userScoresSnapshot = await userScoresFuture;
      QuerySnapshot categoriesSnapshot = await categoriesFuture;

      int totalScore = 0;
      for (var doc in userScoresSnapshot.docs) {
        int highestScore = isUntimed
            ? (doc['highest_score_untimed'] ?? 0)
            : (doc['highest_score'] ?? 0);
        totalScore += highestScore;
      }

      List<Future<int>> questionFutures =
          categoriesSnapshot.docs.map((categoryDoc) async {
        QuerySnapshot questionSnapshot = await _db
            .collection('trivia')
            .doc(categoryDoc.id)
            .collection('questions')
            .get();
        return questionSnapshot.size;
      }).toList();

      List<int> questionCounts = await Future.wait(questionFutures);
      int multiplier = isUntimed ? 1 : 5;
      int maxPossibleScore =
          questionCounts.fold(0, (sum, count) => sum + count * multiplier);

      return {
        'totalScore': totalScore,
        'maxPossibleScore': maxPossibleScore,
      };
    } catch (e) {
      return {'totalScore': 0, 'maxPossibleScore': 0};
    }
  }

  /// Stream for watching payment sessions in Firestore.
  Stream<QuerySnapshot> getPaymentSessions(String userId) {
    return _db
        .collection('customers')
        .doc(userId)
        .collection('checkout_sessions')
        .snapshots();
  }

  /**** SCAVENGER HUNT ****/
  /// Fetches unique scavenger hunt categories from Firestore.
  Future<List<String>> fetchScavengerHuntCategories() async {
    try {
      QuerySnapshot snapshot =
          await _db.collection('scavenger_hunt_items').get();

      // Extract unique category names
      Set<String> categories = snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['category'] as String)
          .toSet();

      return categories.toList()..sort(); // Sort alphabetically
    } catch (e) {
      print("❌ Error fetching scavenger hunt categories: $e");
      return [];
    }
  }

  /// Fetches scavenger hunt items by both category and difficulty.
  Future<List<Map<String, dynamic>>> fetchScavengerHuntByCategoryAndDifficulty(
      String category, String difficulty) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('scavenger_hunt_items')
          .where('category', isEqualTo: category)
          .where('difficulty', isEqualTo: difficulty)
          .orderBy('difficultySortOrder')
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print(
          "❌ Error fetching scavenger hunt items by category and difficulty: $e");
      return [];
    }
  }

  /// Fetch scavenger hunt items based on selected criteria
  Future<List<Map<String, dynamic>>> fetchScavengerHuntItems({
    required List<String> categories,
    required String difficulty,
    required int itemCount,
  }) async {
    try {
      print("🛠 Fetching scavenger hunt items...");

      CollectionReference scavengerHuntItems =
          _db.collection('scavenger_hunt_items');

      // 1) Convert all provided categories to lowercase.
      //    (Only do this if you know your Firestore data is also stored in lowercase.)
      List<String> lowerCaseCategories =
          categories.map((c) => c.toLowerCase()).toList();

      Query query = scavengerHuntItems;

      // Step 2: Apply category filter (if not "All")
      if (lowerCaseCategories.isNotEmpty &&
          !lowerCaseCategories.contains("all")) {
        print("📌 Filtering by categories: $lowerCaseCategories");
        query = query.where('category', whereIn: lowerCaseCategories);
      }

      // Step 3: Apply difficulty filter
      if (difficulty != "mix") {
        print("📌 Filtering by difficulty: $difficulty");
        query = query.where('difficulty', isEqualTo: difficulty);
      } else {
        print("📌 'Mix' selected, fetching all difficulties.");
      }

      // Step 4: Fetch extra items for randomness
      int fetchCount = itemCount * 3;
      QuerySnapshot snapshot = await query.limit(fetchCount).get();

      if (snapshot.docs.isEmpty) {
        print("❌ No items matched query.");
        return [];
      }

      // Step 5: Convert documents to list
      List<Map<String, dynamic>> items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "text": data["text"],
          "emoji": data["emoji"],
          "difficulty": data["difficulty"],
          // 2) Force the category to lowercase.
          "category": (data["category"] as String).toLowerCase(),
          "difficultySortOrder": data["difficultySortOrder"],
          "categorySortOrder": data["categorySortOrder"],
          "completed": false, // Default all items to false
        };
      }).toList();

      // Step 6: Shuffle the list to ensure randomness
      items.shuffle();

      // Step 7: Return only the requested number of items
      List<Map<String, dynamic>> selectedItems = items.take(itemCount).toList();

      print("✅ Successfully fetched ${selectedItems.length} items.");
      return selectedItems;
    } catch (e) {
      print("❌ Error fetching scavenger hunt items: $e");
      return [];
    }
  }

  /// Save scavenger hunt to Firestore
  Future<void> saveScavengerHunt({
    required String name,
    required List<String> categories,
    required String difficulty,
    required int itemCount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");


      DocumentReference userRef =
          _db.collection('user_scavenger_hunts').doc(user.uid);
      CollectionReference huntsRef = userRef.collection('hunts');

      // Debugging: Print data before saving
      print("📝 Saving Scavenger Hunt: $name");
      print("📌 Categories: ${categories.join(", ")}");
      print("🎯 Difficulty: $difficulty");
      print("🔢 Item Count: $itemCount");
      print("📋 Items: ${items.map((e) => e['text']).toList()}");

      await huntsRef.add({
        "name": name,
        "categories": categories,
        "difficulty": difficulty,
        "itemCount": itemCount,
        "createdAt": FieldValue.serverTimestamp(),
        "items": items, // Save selected items
      });

      print("✅ Scavenger Hunt saved!");
    } catch (e) {
      print("❌ Error saving scavenger hunt: $e");
    }
  }

  /// Fetch a scavenger hunt by ID
  Future<Map<String, dynamic>?> fetchScavengerHunt(String huntId) async {
    try {
      // User? user = FirebaseAuth.instance.currentUser;
      User? user = FirebaseAuth.instance.currentUser;
      final String userId = user != null ? user.uid ?? "demo_user" : "demo_user"; // For demo purposes

      print("userId: $userId");

      DocumentSnapshot snapshot = await _db
          .collection('user_scavenger_hunts')
          .doc(userId)
          .collection('hunts')
          .doc(huntId)
          .get();


      if (!snapshot.exists) return null;
      return snapshot.data() as Map<String, dynamic>;
    } catch (e) {
      print("❌ Error fetching scavenger hunt: $e");
      return null;
    }
  }

  /// Update scavenger hunt item completion status
  Future<void> updateScavengerHuntItem(
      String huntId, String itemId, bool isCompleted) async {
    try {
      print("UPDATING scav hunt");

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentReference huntRef = _db
          .collection('user_scavenger_hunts')
          .doc(user.uid)
          .collection('hunts')
          .doc(huntId);

      DocumentSnapshot huntSnapshot = await huntRef.get();
      if (!huntSnapshot.exists) return;

      Map<String, dynamic> huntData =
          huntSnapshot.data() as Map<String, dynamic>;
      List<dynamic> items = huntData["items"];

      // Find the specific item and update it
      for (var item in items) {
        if (item["id"] == itemId) {
          item["completed"] = isCompleted;
          break;
        }
      }

      // Update the hunt document in Firestore
      await huntRef.update({"items": items});
      print("✅ Updated item $itemId in hunt $huntId.");
    } catch (e) {
      print("❌ Error updating scavenger hunt item: $e");
    }
  }

  /// Fetch all scavenger hunts for a specific user
  Future<List<Map<String, dynamic>>> fetchUserScavengerHunts(
      String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('user_scavenger_hunts')
          .doc(userId)
          .collection('hunts')
          .orderBy('createdAt', descending: true) // Most recent hunts first
          .get();

      return snapshot.docs.map((doc) {
        return {
          "id": doc.id, // Include the document ID
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print("❌ Error fetching user's scavenger hunts: $e");
      return [];
    }
  }

/**** HEAD TO HEAD CHALLENGE ****/
  Future<String> createGame({
    required String team1Name,
    required String team2Name,
    required int wordsPerTeam,
    required String difficulty,
    required int secondsPerTurn,
    required int rounds,
  }) async {
    try {
      CollectionReference gamesRef = _db.collection('head_to_head_games');

      // Fetch words
      List<Map<String, dynamic>> words =
          await fetchWords(difficulty, wordsPerTeam * rounds * 2);

      DocumentReference gameDoc = await gamesRef.add({
        "team1_name": team1Name,
        "team2_name": team2Name,
        "difficulty": difficulty,
        "words_per_team": wordsPerTeam,
        "seconds_per_turn": secondsPerTurn,
        "rounds": rounds,
        "current_round": 1,
        "current_turn": "team1",
        "score_team1": 0,
        "score_team2": 0,
        "status": "in_progress",
        "words": words,
        "created_at": FieldValue.serverTimestamp(),
      });

      return gameDoc.id;
    } catch (e) {
      print("❌ Error creating game: $e");
      return "";
    }
  }

  Future<List<Map<String, dynamic>>> fetchWords(
      String difficulty, int count) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('challenge_words')
          .where('difficulty', isEqualTo: difficulty)
          .limit(count * 2) // Fetch extra for randomness
          .get();

      List<Map<String, dynamic>> words = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      words.shuffle(); // Shuffle for randomness
      return words.take(count).toList();
    } catch (e) {
      print("❌ Error fetching words: $e");
      return [];
    }
  }

  Future<void> updateTurn({
    required String gameId,
    required bool correctGuess,
  }) async {
    try {
      DocumentReference gameRef =
          _db.collection('head_to_head_games').doc(gameId);
      DocumentSnapshot gameSnap = await gameRef.get();

      if (!gameSnap.exists) return;

      Map<String, dynamic> gameData = gameSnap.data() as Map<String, dynamic>;

      String currentTeam = gameData["current_turn"] ?? "team1";
      int currentRound = gameData["current_round"];
      int totalRounds = gameData["rounds"];

      // Switch turns
      String nextTeam = (currentTeam == "team1") ? "team2" : "team1";
      print("nextTeam: $nextTeam");

      // If both teams have taken a turn, move to next round
      if (nextTeam == "team1") {
        currentRound++;
      }

      // Check if the game is over
      bool isGameOver = currentRound > totalRounds;

      await gameRef.update({
        "current_turn": isGameOver ? "" : nextTeam,
        "current_round": isGameOver ? totalRounds : currentRound,
        "status": isGameOver ? "completed" : "in_progress",
      });
    } catch (e) {
      print("❌ Error updating turn: $e");
    }
  }

  Future<void> endGame(String gameId) async {
    try {
      DocumentReference gameRef =
          _db.collection('head_to_head_games').doc(gameId);
      DocumentSnapshot gameSnap = await gameRef.get();

      if (!gameSnap.exists) return;

      Map<String, dynamic> gameData = gameSnap.data() as Map<String, dynamic>;

      int scoreTeam1 = gameData["score_team1"];
      int scoreTeam2 = gameData["score_team2"];

      String winner = (scoreTeam1 > scoreTeam2)
          ? gameData["team1_name"]
          : (scoreTeam1 < scoreTeam2)
              ? gameData["team2_name"]
              : "Tie";

      await gameRef.update({
        "status": "completed",
        "winner": winner,
        "completed_at": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error ending game: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchGame(String gameId) async {
    try {
      DocumentSnapshot snapshot =
          await _db.collection('head_to_head_games').doc(gameId).get();
      if (!snapshot.exists) return null;
      return snapshot.data() as Map<String, dynamic>;
    } catch (e) {
      print("❌ Error fetching game: $e");
      return null;
    }
  }

  Future<void> updateScore({
    required String gameId,
    required bool correctGuess,
  }) async {
    try {
      DocumentReference gameRef =
          _db.collection('head_to_head_games').doc(gameId);
      DocumentSnapshot gameSnap = await gameRef.get();
      if (!gameSnap.exists) return;

      Map<String, dynamic> gameDataMap =
          gameSnap.data() as Map<String, dynamic>;
      String currentTeam = gameDataMap["current_turn"] ?? "team1";
      int scoreTeam1 = gameDataMap["score_team1"] ?? 0;
      int scoreTeam2 = gameDataMap["score_team2"] ?? 0;

      if (correctGuess) {
        if (currentTeam == "team1") {
          scoreTeam1++;
        } else {
          scoreTeam2++;
        }
      }

      await gameRef.update({
        "score_team1": scoreTeam1,
        "score_team2": scoreTeam2,
      });
    } catch (e) {
      print("Error updating score: $e");
    }
  }
}
