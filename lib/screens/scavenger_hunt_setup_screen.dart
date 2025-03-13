import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';
import 'scavenger_hunt_history_screen.dart';
import 'package:intl/intl.dart';

class ScavengerHuntSetupScreen extends StatefulWidget {
  const ScavengerHuntSetupScreen({Key? key}) : super(key: key);

  @override
  _ScavengerHuntSetupScreenState createState() =>
      _ScavengerHuntSetupScreenState();
}

class _ScavengerHuntSetupScreenState extends State<ScavengerHuntSetupScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  bool _isLoggedIn = false;
  int _itemCount = 10;
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  bool _selectAllCategories = false;
  bool _hasPurchased = false;
  String _selectedDifficulty = 'mix';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserLogin();
    _loadCategories();
    _fetchPurchaseStatus();
  }

  void _fetchPurchaseStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _hasPurchased = false;
        _selectedDifficulty = 'sample';
      });
      return;
    }

    FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['hasPurchased'] == true) {
        setState(() {
          _hasPurchased = true;
          // If the current selection is "sample" but the user is premium, switch to a free option.
          if (_selectedDifficulty == 'sample') {
            _selectedDifficulty = 'easy';
          }
        });
      } else {
        setState(() {
          _hasPurchased = false;
          // Force non-premium users to use "sample".
          _selectedDifficulty = 'sample';
        });
      }
    });
  }

  /// Check if a user is logged in
  void _checkUserLogin() {
    setState(() {
      _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    });
  }

  /// Load unique scavenger hunt categories from Firestore
  void _loadCategories() async {
    List<String> fetchedCategories =
        await _firestoreService.fetchScavengerHuntCategories();
    setState(() {
      _categories = fetchedCategories.map((c) => _capitalize(c)).toList();

      // Start with "All" selected
      _selectAllCategories = true;
      _selectedCategories = List.from(_categories);
    });
  }

  /// Capitalize category names
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Toggle 'All' category behavior
  void _toggleAllCategories(bool selected) {
    setState(() {
      _selectAllCategories = selected;
      if (selected) {
        _selectedCategories = List.from(_categories);
      } else {
        _selectedCategories.clear();
      }
    });
  }

  /// Toggle individual category selection
  void _toggleCategorySelection(String category, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
      _selectAllCategories = _selectedCategories.length == _categories.length;
    });
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ');
  }

  /// Generate a unique scavenger hunt and save it in Firestore
  Future<void> _generateScavengerHunt() async {
    // if (!_isLoggedIn) return;

    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? "demo_user";

    // Use date & time as hunt name
    String huntName = DateFormat('MM-dd-yyyy hh:mm a').format(DateTime.now());

   List<Map<String, dynamic>> items =
        await _firestoreService.fetchScavengerHuntItems(
      categories: _selectedCategories,
      difficulty: _selectedDifficulty,
      itemCount: _itemCount,
    );

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No items found for this selection.")),
      );
      return;
    }

    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('user_scavenger_hunts')
          .doc(userId)
          .collection('hunts')
          .add({
        "name": huntName,
        "categories": _selectedCategories,
        "difficulty": _selectedDifficulty,
        "itemCount": _itemCount,
        "items": items,
        "createdAt": FieldValue.serverTimestamp(),
      });

      String huntId = docRef.id;
     
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Scavenger Hunt '$huntName' Created!")),
      );

      GoRouter.of(context).go('/scavenger-hunt/play/$huntId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error creating scavenger hunt")),
      );
    }
  }

  /// Build the "Generate New Hunt" tab content.
  Widget _buildNewHuntTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Categories:", style: TextStyle(fontSize: 12)),
            CheckboxListTile(
              title: const Text("All"),
              value: _selectAllCategories,
              onChanged: (val) {
                if (val != null) {
                  _toggleAllCategories(val);
                }
              },
            ),
            Column(
              children: _categories.map((category) {
                return CheckboxListTile(
                  title: Text(_formatCategory(category)),
                  value: _selectedCategories.contains(category),
                  onChanged: (val) {
                    if (val != null) {
                      _toggleCategorySelection(category, val);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: _itemCount,
              decoration: const InputDecoration(
                  labelText: 'Number of Scavenger Hunt Items'),
              items: List.generate(100, (index) => index + 1).map((number) {
                return DropdownMenuItem<int>(
                  value: number,
                  child: Text(number.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _itemCount = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text("Select Difficulty:", style: TextStyle(fontSize: 12)),
            Column(
              children: _hasPurchased
                  ? [
                      // Premium users: enable free options and disable "Sample".
                      ...["easy", "medium", "hard", "mix"].map((difficulty) {
                        return RadioListTile<String>(
                          title: Text(
                            toBeginningOfSentenceCase(difficulty) ?? difficulty,
                            style: const TextStyle(color: Colors.black),
                          ),
                          value: difficulty,
                          groupValue: _selectedDifficulty,
                          onChanged: (val) {
                            setState(() {
                              _selectedDifficulty = val!;
                            });
                          },
                        );
                      }).toList()
                    ]
                  : [
                      // Non-premium users: disable free options and enable only "Sample".
                      ...["easy", "medium", "hard", "mix"].map((difficulty) {
                        return RadioListTile<String>(
                          title: Text(
                            toBeginningOfSentenceCase(difficulty) ?? difficulty,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          value: difficulty,
                          groupValue: _selectedDifficulty,
                          onChanged: null, // Disabled.
                        );
                      }).toList(),
                      RadioListTile<String>(
                        title: const Text("Sample",
                            style: TextStyle(color: Colors.black)),
                        value: "sample",
                        groupValue: _selectedDifficulty,
                        onChanged: (val) {
                          setState(() {
                            _selectedDifficulty = val!;
                          });
                        },
                      ),
                    ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C)),
                onPressed: () {
                  _generateScavengerHunt();
                },
                child: const Text(
                  'Generate Scavenger Hunt',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the "Play Past Hunts" tab content.
  Widget _buildPastHuntsTab() {
    return Container(
      child: const ScavengerHuntHistoryPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to fill 100% of the screen (after the appbar)
    return Scaffold(
      appBar: CustomAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          return Container(
            width: double.infinity,
            height: availableHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Container(
                  width: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Header above the white box, in white and left justified.
                      const Text(
                        "Scavenger Hunt Setup",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.start,
                      ),

                      const SizedBox(height: 10),
                      Container(
                        width: 600,
                        height: availableHeight,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Internal header inside the white box (optional; remove if not desired)
                            // const Text(
                            //   "Scavenger Hunt Setup",
                            //   style: TextStyle(
                            //     fontSize: 24,
                            //     fontWeight: FontWeight.bold,
                            //     color: Colors.black,
                            //   ),
                            // ),
                            // const SizedBox(height: 10),
                            TabBar(
                              controller: _tabController,
                              labelColor: Colors.black,
                              indicatorColor: const Color(0xFF4A148C),
                              tabs: const [
                                Tab(text: "Generate New Hunt"),
                                Tab(text: "Play Past Hunts"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildNewHuntTab(),
                                  _buildPastHuntsTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
