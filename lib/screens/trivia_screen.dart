import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class TriviaListScreen extends StatefulWidget {
  final bool isUntimed; // true for untimed mode

  // Callbacks (onTriviaSelected, onReturnToHome) can be added as needed.
  const TriviaListScreen({
    Key? key,
    required void Function(String quizId) onTriviaSelected,
    required this.isUntimed,
    required void Function() onReturnToHome,
  }) : super(key: key);

  @override
  State<TriviaListScreen> createState() => _TriviaListScreenState();
}

class _TriviaListScreenState extends State<TriviaListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, List<int>> _categoryLevels = {};
  Map<String, Map<int, int>> _highScores = {};
  Map<String, Map<int, int>> _categoryQuestionCounts = {};
  bool _isLoading = true;
  String? _expandedCategory;
  String? _hoveredLevelKey;
  int _totalUserScore = 0;
  int _maxPossibleScore = 0;
  Map<String, Map<String, int>> _categoryScores = {};
  bool _hasPurchased = false;
  List<String> _orderedCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _fetchPurchaseStatus();
  }

  void _fetchInitialData() {
    _fetchCategoriesAndLevels();
    _fetchTotalUserScore();
    _fetchCategoryScores();
  }

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
        });
      }
    });
  }

  void _fetchCategoryScores() async {
    Map<String, Map<String, int>> scores = await _firestoreService
        .fetchCategoryScores(isUntimed: widget.isUntimed);
    setState(() {
      _categoryScores = scores;
    });
  }

  void _fetchTotalUserScore() async {
    Map<String, int> scores = await _firestoreService.fetchTotalUserScore(
        isUntimed: widget.isUntimed);
    setState(() {
      _totalUserScore = scores['totalScore']!;
      _maxPossibleScore = scores['maxPossibleScore']!;
    });
  }

  void _fetchCategoriesAndLevels() async {
    List<String> fetchedCategories = await _firestoreService.fetchCategories();
    if (_hasPurchased) {
      fetchedCategories =
          fetchedCategories.where((c) => c.toLowerCase() != "sample").toList();
    }
    _orderedCategories = List.from(fetchedCategories);
    List<Future<void>> futures = _orderedCategories.map((category) async {
      List<int> levels = await _firestoreService.fetchAvailableLevels(category);
      List<Future<Map<String, dynamic>>> levelFutures =
          levels.map((level) async {
        int score = await _firestoreService.getHighestScore(category, level,
            isUntimed: widget.isUntimed);
        int? count =
            await _firestoreService.fetchQuestionCount(category, level);
        return {'level': level, 'score': score, 'count': count};
      }).toList();
      List<Map<String, dynamic>> results = await Future.wait(levelFutures);
      _categoryLevels[category] = levels;
      _highScores[category] = {
        for (var res in results) res['level'] as int: res['score'] as int
      };
      _categoryQuestionCounts[category] = {
        for (var res in results) res['level'] as int: res['count'] as int
      };
    }).toList();
    await Future.wait(futures);
    setState(() {
      _isLoading = false;
    });
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayedCategories = _hasPurchased
        ? _orderedCategories
            .where((cat) => cat.toLowerCase() != "sample")
            .toList()
        : _orderedCategories;
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(20),
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Purchase) Section wrapped in Center to keep it centered.
                          Center(
                            child: _hasPurchased
                                ? Image.asset("/images/mg-header-new.jpg")
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            GoRouter.of(context).go('/payment'),
                                        child: Image.asset(
                                            "/images/mg-header-new.jpg"),
                                      ).showCursorOnHover,
                                      ElevatedButton(
                                        onPressed: () =>
                                            GoRouter.of(context).go('/payment'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromRGBO(
                                              244, 184, 96, 1.0),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24, horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(0)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.lock_outline),
                                            SizedBox(width: 4),
                                            Text(
                                              "Unlock - \$2.99",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Color(0xFF4A148C)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 20),
                          // Headlines left-aligned.
                          widget.isUntimed
                              ? Text(
                                  "Solo Trivia (Untimed)",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.start,
                                )
                              : Text(
                                  "Solo Trivia (Timed)",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                          const SizedBox(height: 20),
                          // ExpansionPanelList of trivia categories.
                          ExpansionPanelList(
                            elevation: 1,
                            expandedHeaderPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            expansionCallback: (index, isExpanded) {
                              String cat = displayedCategories.elementAt(index);
                              setState(() {
                                _expandedCategory =
                                    (_expandedCategory == cat) ? null : cat;
                              });
                            },
                            children: displayedCategories.map((category) {
                              bool isExpanded = _expandedCategory == category;
                              return ExpansionPanel(
                                canTapOnHeader: true,
                                isExpanded: isExpanded,
                                headerBuilder: (context, isExpanded) {
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _expandedCategory =
                                            (_expandedCategory == category)
                                                ? null
                                                : category;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatCategory(category),
                                                style: const TextStyle(
                                                  color: Color(0xFF4A148C),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "${_categoryLevels[category]?.length ?? 0} Quizzes · ${_categoryQuestionCounts[category]?.values.reduce((a, b) => a + b) ?? 0} Questions",
                                                style: const TextStyle(
                                                  color: Color(0xFF4A148C),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              // Replace "High Score Total" row with a RatingBarIndicator.
                                              Builder(builder: (context) {
                                                final int earnedScore =
                                                    _categoryScores[category]?['earnedScore'] ??
                                                        0;
                                                final int maxScore =
                                                    _categoryScores[category]?['maxPossibleScore'] ??
                                                        0;
                                                final double rating = maxScore > 0
                                                    ? (earnedScore / maxScore * 5)
                                                    : 0;
                                                return Row(
                                                  children: [
                                                    RatingBarIndicator(
                                                      rating: rating,
                                                      itemBuilder: (context, index) =>
                                                          const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                      direction: Axis.horizontal,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "$earnedScore / $maxScore",
                                                      style: const TextStyle(
                                                        color: Color(0xFF4A148C),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                body: Column(
                                  children: _categoryLevels[category]!.map((level) {
                                    String levelKey = "$category-$level";
                                    // Compute the dynamic rating:
                                    final int score =
                                        _highScores[category]?[level] ?? 0;
                                    final int maxScore = (_categoryQuestionCounts[category]?[level] ?? 0) *
                                        (widget.isUntimed ? 1 : 5);
                                    final double rating =
                                        maxScore > 0 ? (score / maxScore * 5) : 0;
                                    return MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _hoveredLevelKey = levelKey),
                                      onExit: (_) =>
                                          setState(() => _hoveredLevelKey = null),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!_hasPurchased) {
                                            if (category.toLowerCase() != "sample") {
                                              GoRouter.of(context).go('/payment');
                                            } else {
                                              if (widget.isUntimed) {
                                                GoRouter.of(context).go(
                                                    '/untimed/trivia/$category/$level');
                                              } else {
                                                GoRouter.of(context).go(
                                                    '/trivia/$category/$level');
                                              }
                                            }
                                          } else {
                                            if (widget.isUntimed) {
                                              GoRouter.of(context).go(
                                                  '/untimed/trivia/$category/$level');
                                            } else {
                                              GoRouter.of(context).go(
                                                  '/trivia/$category/$level');
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _hoveredLevelKey == levelKey
                                                ? const Color.fromARGB(
                                                    255, 241, 222, 255)
                                                : (!_hasPurchased &&
                                                        (category.toLowerCase() !=
                                                            "sample")
                                                    ? Colors.grey[200]
                                                    : const Color.fromARGB(
                                                        255, 231, 207, 248)),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Level $level",
                                                style: TextStyle(
                                                  color: !_hasPurchased &&
                                                          (category.toLowerCase() !=
                                                              "sample")
                                                      ? Colors.grey[600]
                                                      : const Color(0xFF4A148C),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  RatingBarIndicator(
                                                    rating: rating,
                                                    itemBuilder: (context, index) =>
                                                        const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                    itemCount: 5,
                                                    itemSize: 20.0,
                                                    direction: Axis.horizontal,
                                                  ),
                                                  Text(
                                                    "$score / $maxScore",
                                                    style: TextStyle(
                                                      color: !_hasPurchased &&
                                                              (category.toLowerCase() !=
                                                                  "sample")
                                                          ? Colors.grey[600]
                                                          : const Color(0xFF4A148C),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: _hoveredLevelKey ==
                                                          levelKey
                                                      ? (!_hasPurchased &&
                                                              (category.toLowerCase() != "sample")
                                                          ? Colors.grey[500]
                                                          : const Color(
                                                              0xFF9D00CC))
                                                      : (!_hasPurchased &&
                                                              (category.toLowerCase() != "sample")
                                                          ? Colors.grey[400]
                                                          : const Color(
                                                              0xFF4A148C)),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      !_hasPurchased &&
                                                              (category.toLowerCase() != "sample")
                                                          ? Icons.lock_outline
                                                          : Icons.play_arrow_sharp,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      !_hasPurchased &&
                                                              (category.toLowerCase() != "sample")
                                                          ? ""
                                                          : "Play",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ).showCursorOnHover;
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ).showCursorOnHover,
            ),
          ),
        ),
      ),
    );
  }
}
