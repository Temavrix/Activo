import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IntermediatePage extends StatefulWidget {
  const IntermediatePage({super.key});

  @override
  State<IntermediatePage> createState() => _BeginnerPageState();
}

class _BeginnerPageState extends State<IntermediatePage> {
  final List<String> beginnerExercises = [
    "Squat",
    "Pushup",
    "Forward and backward lunge",
    "Plank",
    "Superman",
  ];

  final Map<String, String> exerciseDescriptions = {
    "Squat":
        "Lowering the hips back and down while keeping the chest up and knees aligned. || Build strength, improve mobility and support overall functional movement.",
    "Pushup":
        "Lowering and raising the body using arm strength while maintaining a straight plank position. || Upper-body exercise that targets the chest, shoulders, triceps.",
    "Forward and backward lunge":
        "It involves stepping one leg forward into a lunge returning to center then stepping the same leg backward into another lunge. || Targets the quads, glutes and hamstrings.",
    "Plank":
        "Holding a straight, rigid body position supported on the forearms or hands and toes. || Improve core strength, stability and posture.",
    "Superman":
        "While lying on your front it involves lifting the arms, chest and legs off the ground simultaneously. || Improve posture, core stability and spinal strength.",
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
      appBar: AppBar(title: const Text("Intermediate Exercises")),
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
