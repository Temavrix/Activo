import 'package:flutter/material.dart';
import 'beginner.dart';
import 'intermediate.dart';
import 'advanced.dart';

class ChooseExercisePage extends StatelessWidget {
  const ChooseExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Exercise Level")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLevelBox(context, "Beginner", BeginnerPage()),
            const SizedBox(height: 16),
            _buildLevelBox(context, "Intermediate", const IntermediatePage()),
            const SizedBox(height: 16),
            _buildLevelBox(context, "Advanced", const AdvancedPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBox(BuildContext context, String title, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 35, 35, 36),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
