import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'choose_exercise.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, bool> checkedExercises = {};

  int streakCount = 0;
  bool loadingStreak = true;

  @override
  void initState() {
    super.initState();
    loadCheckboxState();
    updateStreak();
  }

  Future<void> loadCheckboxState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      for (var key in keys) {
        if (key != 'lastLoginDate' && key != 'streakCount') {
          checkedExercises[key] = prefs.getBool(key) ?? false;
        }
      }
    });
  }

  Future<void> saveCheckboxState(String exercise, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(exercise, value);
  }

  Future<void> resetCheckboxes() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep streak keys intact, remove only exercise keys
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key != 'lastLoginDate' && key != 'streakCount') {
        await prefs.remove(key);
      }
    }
    setState(() {
      checkedExercises.updateAll((key, value) => false);
    });
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    String todayStr = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // yyyy-MM-dd
    String? lastLoginDate = prefs.getString('lastLoginDate');
    int currentStreak = prefs.getInt('streakCount') ?? 0;

    if (lastLoginDate == todayStr) {
      // Already logged in today, no change
    } else if (lastLoginDate != null) {
      DateTime lastDate = DateTime.parse(lastLoginDate);
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

      if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        // Last login was yesterday - increment streak
        currentStreak += 1;
      } else {
        // Last login was more than 1 day ago - reset streak
        currentStreak = 1;
      }
    } else {
      // No lastLoginDate found - first time login
      currentStreak = 1;
    }

    await prefs.setString('lastLoginDate', todayStr);
    await prefs.setInt('streakCount', currentStreak);

    setState(() {
      streakCount = currentStreak;
      loadingStreak = false;
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    // Optionally navigate to login screen here if you have one
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: loadingStreak
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      '🔥 Exercise Streak: $streakCount day${streakCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseExercisePage(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 57, 58, 59),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Add Exercises",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Your Exercises",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        onPressed: resetCheckboxes,
                        tooltip: 'Reset checklist',
                      ),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('exercises')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var docs = snapshot.data!.docs;
                        return ListView(
                          children: docs.map((doc) {
                            String name;
                            try {
                              name = doc['name'];
                            } catch (e) {
                              name =
                                  doc.id; // fallback if "name" field is missing
                            }
                            bool isChecked = checkedExercises[name] ?? false;
                            return CheckboxListTile(
                              title: Text(name),
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  checkedExercises[name] = value ?? false;
                                });
                                saveCheckboxState(name, value ?? false);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
