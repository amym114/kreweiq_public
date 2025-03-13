import 'package:flutter/material.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(maxWidth: 976),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Vertical stacking: first the text, then the image.
                  Text(
                    "It all started about a month before the first big parades. My 9‑year‑old son, my sister, and I were hanging out on the front porch, counting down the days to Mardi Gras. My son was buzzing with excitement for the season, and before we knew it, we were tossing out trivia questions about everything Mardi Gras—from when the parades roll to history to all the quirky traditions that make the festival so special.\n\n"
                    "That fun little trivia battle got me thinking: why not turn our porch game into something everyone can enjoy? As a software engineer and a huge Mardi Gras fan, I decided to create Krewe IQ—a Mardi Gras Trivia App packed with cool questions and fun facts about the celebration we all love.\n\n"
                    "With Krewe IQ, you can test your knowledge on the history, legends, and traditions of Mardi Gras in a relaxed, interactive way. Whether you’re a local who knows every secret or just curious to learn more about the magic of Mardi Gras, our app is your perfect sidekick while you wait for the next parade to roll by. Enjoy the trivia and let the good times roll!",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Insert the image below the text
                  Center(
                    child: Image.asset(
                      "images/photo-in-frame.jpg", // Replace with your image asset path
                      width: MediaQuery.of(context).size.width < 600
                          ? MediaQuery.of(context).size.width
                          : MediaQuery.of(context).size.width * 0.4,
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
