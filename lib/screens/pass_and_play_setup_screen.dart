import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';

class PassAndPlaySetupScreen extends StatefulWidget {
  final String? initialPlayer1Name;
  final String? initialPlayer2Name;
  final int? initialQuestionCount;
  final bool? initialIsKids;
  final bool? initialEasy;
  final bool? initialHard;
  final bool? initialMix;
  final int? initialTimerDuration; // NEW

  const PassAndPlaySetupScreen({
    Key? key,
    this.initialPlayer1Name,
    this.initialPlayer2Name,
    this.initialQuestionCount,
    this.initialIsKids,
    this.initialEasy,
    this.initialHard,
    this.initialMix,
    this.initialTimerDuration, // NEW
  }) : super(key: key);

  @override
  _PassAndPlaySetupScreenState createState() => _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState extends State<PassAndPlaySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late String player1Name;
  late String player2Name;
  late int questionCount;
  late String selectedDifficulty;
  bool _hasPurchased = false;
  late int selectedTimerDuration; // This will be set in initState

  // Force "sample" if not logged in or not purchased.
  bool get _shouldShowSample =>
      FirebaseAuth.instance.currentUser == null || !_hasPurchased;

  @override
  @override
  void initState() {
    super.initState();
    player1Name = widget.initialPlayer1Name ?? 'Player 1';
    player2Name = widget.initialPlayer2Name ?? 'Player 2';
    questionCount = widget.initialQuestionCount ?? 5;
    // Use the passed timer duration (if any) or default to 15.
    selectedTimerDuration = widget.initialTimerDuration ?? 30;

    _checkPurchaseStatus();

    if (_shouldShowSample) {
      selectedDifficulty = "sample";
    } else if (widget.initialIsKids == true) {
      selectedDifficulty = "kids";
    } else if (widget.initialEasy == true) {
      selectedDifficulty = "easy";
    } else if (widget.initialHard == true) {
      selectedDifficulty = "hard";
    } else if (widget.initialMix == true) {
      selectedDifficulty = "mix";
    } else {
      selectedDifficulty = "mix";
    }
  }

  void _checkPurchaseStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _hasPurchased = false;
      });
      return;
    }
    FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get()
        .then((doc) {
      bool purchased = doc.exists && doc.data()?['hasPurchased'] == true;
      setState(() {
        _hasPurchased = purchased;
        if (purchased && selectedDifficulty == "sample") {
          // If purchased, choose a normal default.
          if (widget.initialEasy == true) {
            selectedDifficulty = "easy";
          } else if (widget.initialHard == true) {
            selectedDifficulty = "hard";
          } else if (widget.initialMix == true) {
            selectedDifficulty = "mix";
          } else {
            selectedDifficulty = "mix";
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGroupValue =
        _shouldShowSample ? "sample" : selectedDifficulty;

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
              padding: const EdgeInsets.only(
                  top: 10, left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hasPurchased
                      ? Image.asset(
                          "/images/mg-header-new.jpg",
                          width: 600,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => GoRouter.of(context).go('/payment'),
                              child: Image.asset("/images/mg-header-new.jpg",
                                  width: 600),
                            ).showCursorOnHover,
                            ElevatedButton(
                              onPressed: () =>
                                  GoRouter.of(context).go('/payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(244, 184, 96, 1.0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.lock_outline),
                                  SizedBox(width: 4),
                                  Text(
                                    "Unlock - \$2.99",
                                    style: TextStyle(
                                        fontSize: 20, color: Color(0xFF4A148C)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 10),
                  const Text(
                    "Pass and Play Setup",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: player1Name,
                                      decoration: const InputDecoration(
                                          labelText: 'Player 1 Name'),
                                      onChanged: (value) => player1Name = value,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: player2Name,
                                      decoration: const InputDecoration(
                                          labelText: 'Player 2 Name'),
                                      onChanged: (value) => player2Name = value,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButtonFormField<int>(
                                value: questionCount,
                                decoration: const InputDecoration(
                                  labelText: 'Number of Questions',
                                ),
                                items: List.generate(10, (index) => index + 1)
                                    .map((number) => DropdownMenuItem<int>(
                                          value: number,
                                          child: Text(number.toString()),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      questionCount = value;
                                    });
                                  }
                                },
                              ),
                              DropdownButtonFormField<int>(
                                value: selectedTimerDuration,
                                decoration: const InputDecoration(
                                  labelText: 'Timer Duration (seconds)',
                                ),
                                items: [15, 30, 45, 60, 75, 90, 105, 120]
                                    .map((sec) {
                                  return DropdownMenuItem<int>(
                                    value: sec,
                                    child: Text('$sec seconds'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedTimerDuration = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Select Difficulty:",
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.start,
                              ),
                              ListTileTheme(
                                data: ListTileThemeData(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  minVerticalPadding: 0,
                                  visualDensity: VisualDensity(
                                      horizontal: 0, vertical: -4),
                                ),
                                child: Column(
                                  children: [
                                    if (_shouldShowSample)
                                      RadioListTile<String>(
                                        title: const Text("Sample",
                                            style:
                                                TextStyle(color: Colors.black)),
                                        value: "sample",
                                        groupValue: effectiveGroupValue,
                                        onChanged: (val) {
                                          setState(() {
                                            selectedDifficulty = val!;
                                          });
                                        },
                                      ),
                                    RadioListTile<String>(
                                      title: Text("Kids",
                                          style: TextStyle(
                                              color: _shouldShowSample
                                                  ? Colors.grey
                                                  : Colors.black)),
                                      value: "kids",
                                      groupValue: effectiveGroupValue,
                                      onChanged: _shouldShowSample
                                          ? null
                                          : (val) {
                                              setState(() {
                                                selectedDifficulty = val!;
                                              });
                                            },
                                    ),
                                    RadioListTile<String>(
                                      title: Text("Easy",
                                          style: TextStyle(
                                              color: _shouldShowSample
                                                  ? Colors.grey
                                                  : Colors.black)),
                                      value: "easy",
                                      groupValue: effectiveGroupValue,
                                      onChanged: _shouldShowSample
                                          ? null
                                          : (val) {
                                              setState(() {
                                                selectedDifficulty = val!;
                                              });
                                            },
                                    ),
                                    RadioListTile<String>(
                                      title: Text("Hard",
                                          style: TextStyle(
                                              color: _shouldShowSample
                                                  ? Colors.grey
                                                  : Colors.black)),
                                      value: "hard",
                                      groupValue: effectiveGroupValue,
                                      onChanged: _shouldShowSample
                                          ? null
                                          : (val) {
                                              setState(() {
                                                selectedDifficulty = val!;
                                              });
                                            },
                                    ),
                                    RadioListTile<String>(
                                      title: Text("Mix",
                                          style: TextStyle(
                                              color: _shouldShowSample
                                                  ? Colors.grey
                                                  : Colors.black)),
                                      value: "mix",
                                      groupValue: effectiveGroupValue,
                                      onChanged: _shouldShowSample
                                          ? null
                                          : (val) {
                                              setState(() {
                                                selectedDifficulty = val!;
                                              });
                                            },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A148C),
                                  ),
                                  onPressed: () {
                                    Map<String, dynamic> extras = {
                                      'isPassAndPlay': true,
                                      'player1': player1Name,
                                      'player2': player2Name,
                                      'questionCount': questionCount,
                                      'selectedDifficulty': _shouldShowSample
                                          ? "sample"
                                          : selectedDifficulty,
                                      'isKids': _shouldShowSample
                                          ? false
                                          : (selectedDifficulty == "kids"),
                                      'timerDuration': selectedTimerDuration,
                                    };
                                    GoRouter.of(context).go(
                                      '/pass-and-play/${_shouldShowSample ? "sample" : selectedDifficulty}',
                                      extra: extras,
                                    );
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
                      ],
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
