import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeginnerPage extends StatefulWidget {
  const BeginnerPage({super.key});

  @override
  State<BeginnerPage> createState() => _BeginnerPageState();
}

class _BeginnerPageState extends State<BeginnerPage> {
  final List<String> beginnerExercises = [
    "Bridge",
    "Chair Squat",
    "Knee Pushup",
    "Knee Plank",
    "Stationary lunge",
    "Bicycle crunch",
  ];

  final Map<String, String> exerciseDescriptions = {
    "Bridge":
        "Lifting the hips off the ground while lying on your back with tucked in knees. || Improves core stability enhances posture and hip mobility.",
    "Chair Squat":
        "Traditional squat exercise that uses a chair or bench as a guide or target. || Building lower body strength and improving mobility and balance.",
    "Knee Pushup":
        "Modified push-up that reduces body weight load by keeping the knees on the ground. || Targets the chest, shoulders and triceps while building upper body strength.",
    "Knee Plank":
        "It involves holding a plank position with the knees on the ground. || Builds strength in the abs, back and shoulders",
    "Stationary lunge":
        "Stepping one foot forward and lowering into a lunge without moving the feet. || Improves balance, strength, and stability.",
    "Bicycle crunch":
        "Lying on your back and alternating elbow-to-knee movements. || Targets the abs and obliques improves core strength and rotational stability.",
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
      appBar: AppBar(title: const Text("Beginner Exercises")),
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
