import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IntermediatePage extends StatefulWidget {
  const IntermediatePage({super.key});

  @override
  State<IntermediatePage> createState() => _IntermediatePageState();
}

class _IntermediatePageState extends State<IntermediatePage> {
  final List<String> intermediateExercises = ["Pull Ups", "Lunges", "Burpees"];

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, double> setsCount = {};

  @override
  void initState() {
    super.initState();
    for (var ex in intermediateExercises) {
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
    var snapshots =
        await FirebaseFirestore.instance
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
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('exercises')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var savedExercises =
              snapshot.data!.docs
                  .where(
                    (doc) =>
                        doc.data() != null &&
                        (doc.data() as Map<String, dynamic>).containsKey(
                          'name',
                        ),
                  )
                  .map((doc) => doc['name'] as String)
                  .toList();

          return ListView.builder(
            itemCount: intermediateExercises.length,
            itemBuilder: (context, index) {
              final exercise = intermediateExercises[index];

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
                      Text(
                        isAdded
                            ? savedExercises.firstWhere(
                              (saved) => saved.startsWith(exercise),
                            )
                            : "$exercise for ${setsCount[exercise]!.toInt()} sets",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: setsCount[exercise]!,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: "${setsCount[exercise]!.toInt()} sets",
                        onChanged:
                            isAdded
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
                            backgroundColor:
                                isAdded ? Colors.red : Colors.green,
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
