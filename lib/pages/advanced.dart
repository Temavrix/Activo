import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdvancedPage extends StatefulWidget {
  const AdvancedPage({super.key});

  @override
  State<AdvancedPage> createState() => _BeginnerPageState();
}

class _BeginnerPageState extends State<AdvancedPage> {
  final List<String> beginnerExercises = [
    "Overhead squat",
    "One-legged pushup",
    "One-leg forearm plank hold",
    "Russian Twist",
    "Hollow hold to jackknife",
  ];

  final Map<String, String> exerciseDescriptions = {
    "Overhead squat":
        "Involves squatting while holding a weight / raising your arm overhead. || Targets the legs, core, shoulders and upper back.",
    "One-legged pushup":
        "It involves lifting one leg off the ground while performing push-ups, challenging balance and stability. || Targets the chest, triceps, shoulders and core more intensely.",
    "One-leg forearm plank hold":
        "Intensifies the traditional plank by lifting one leg off the ground. || Targets the abs, glutes, shoulders and lower back while challenging balance and stability.",
    "Russian Twist":
        "It involves sitting with feet off the ground and twisting the torso side to side often holding a weight or medicine ball. || This move improves rotational strength, balance, and core stability.",
    "Hollow hold to jackknife":
        "It starts by laying on your back and transitions into a jackknife by banding and lifting the arms and legs to meet at the top. || Movement builds core strength, control and coordination.",
  };

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // Store sets count for each exercise locally (default 1)
  final Map<String, double> setsCount = {};

  @override
  void initState() {
    super.initState();
    for (var ex in beginnerExercises) {
      setsCount[ex] = 1;
    }
  }

  void addExercise(String name, int sets) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .add({'name': "$name for $sets sets"});
  }

  void removeExercise(String name) async {
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .get();

    for (var doc in snapshots.docs) {
      if ((doc.data()['name'] as String).startsWith(name)) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advanced Exercises")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('exercises')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter docs to only those with 'name' field
          var savedExercises = snapshot.data!.docs
              .where(
                (doc) =>
                    doc.data() != null &&
                    (doc.data() as Map<String, dynamic>?)?.containsKey(
                          'name',
                        ) ==
                        true,
              )
              .map((doc) => doc['name'] as String)
              .toList();

          return ListView.builder(
            itemCount: beginnerExercises.length,
            itemBuilder: (context, index) {
              final exercise = beginnerExercises[index];

              final isAdded = savedExercises.any(
                (saved) => saved.startsWith(exercise),
              );

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and sets info
                      Text(
                        isAdded
                            ? savedExercises.firstWhere(
                                (saved) => saved.startsWith(exercise),
                              )
                            : "$exercise for ${setsCount[exercise]!.toInt()} sets",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description below title
                      Text(
                        exerciseDescriptions[exercise] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      Slider(
                        value: setsCount[exercise]!,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: "${setsCount[exercise]!.toInt()} sets",
                        onChanged: isAdded
                            ? null
                            : (value) {
                                setState(() {
                                  setsCount[exercise] = value;
                                });
                              },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isAdded ? Icons.delete : Icons.add,
                            color: Colors.white,
                          ),
                          label: Text(isAdded ? "Delete" : "Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdded
                                ? Colors.red
                                : Colors.green,
                          ),
                          onPressed: () {
                            if (isAdded) {
                              removeExercise(exercise);
                            } else {
                              addExercise(
                                exercise,
                                setsCount[exercise]!.toInt(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
