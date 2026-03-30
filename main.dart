import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

const String apiKey = "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";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "AI Mock Interview App",
      home: FieldScreen(),
    );
  }
}

// 🔹 SCREEN 1: FIELD SELECT
class FieldScreen extends StatelessWidget {
  final List<String> fields = [
    "App Development",
    "Web Development",
    "Software Development"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Field")),
      body: ListView(
        children: fields.map((field) {
          return ListTile(
            title: Text(field),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TechScreen(field: field),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

// 🔹 SCREEN 2: TECHNOLOGY SELECT
class TechScreen extends StatelessWidget {
  final String field;

  TechScreen({required this.field});

  final Map<String, List<String>> techMap = {
    "App Development": ["Flutter", "React Native"],
    "Web Development": ["HTML", "CSS", "JavaScript", "React"],
    "Software Development": ["Java", "Python", "C++", "PHP"]
  };

  @override
  Widget build(BuildContext context) {
    List<String> techs = techMap[field]!;

    return Scaffold(
      appBar: AppBar(title: Text("Select Technology")),
      body: ListView(
        children: techs.map((tech) {
          return ListTile(
            title: Text(tech),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterviewScreen(tech: tech),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

// 🔹 SCREEN 3: INTERVIEW
class InterviewScreen extends StatefulWidget {
  final String tech;

  InterviewScreen({required this.tech});

  @override
  _InterviewScreenState createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  String question = "";
  String result = "";
  bool loading = false;

  TextEditingController controller = TextEditingController();
  
  get history => null;

  // ✅ Generate Question
 Future<void> getQuestion() async {
  setState(() {
    loading = true;
    question = "";
    result = "";
    controller.clear();
  });

  try {
    final response = await http
        .post(
          Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "model": "openai/gpt-3.5-turbo",
            "messages": [
              {
                "role": "user",
                "content": """
Generate a UNIQUE ${widget.tech} interview question.

Avoid repetition.
Make it practical and different.
"""
              }
            ]
          }),
        )
        .timeout(Duration(seconds: 15)); // ⏱ timeout add

    print("API RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["choices"] != null &&
          data["choices"].length > 0 &&
          data["choices"][0]["message"] != null) {
        setState(() {
          question = data["choices"][0]["message"]["content"];
          loading = false;
        });
      } else {
        setState(() {
          question = "No question received!";
          loading = false;
        });
      }
    } else {
      setState(() {
        question = "Error: ${response.body}";
        loading = false;
      });
    }
  } catch (e) {
    setState(() {
      question = "Exception: $e";
      loading = false;
    });
  }
}
  // ✅ Evaluate Answer
  Future<void> checkAnswer() async {
    String ans = controller.text.trim();

    if (ans.isEmpty || ans.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Write proper answer!")),
      );
      return;
    }

    setState(() {
      loading = true;
      result = "";
    });

    final response = await http.post(
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "messages": [
          {
            "role": "user",
            "content": """
You are a strict interviewer.

Question: $question
User Answer: $ans

Give:
- Score
- Mistakes
- Correct Answer
- Tips
"""
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    setState(() {
      result = data["choices"][0]["message"]["content"];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tech)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: getQuestion,
              child: Text("Get Question"),
            ),

            SizedBox(height: 20),

            if (loading) CircularProgressIndicator(),

            if (question.isNotEmpty) Text(question),

            SizedBox(height: 20),

            if (question.isNotEmpty)
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Type your answer",
                ),
              ),

            SizedBox(height: 10),

            if (question.isNotEmpty)
              ElevatedButton(
                onPressed: checkAnswer,
                child: Text("Submit"),
              ),

            SizedBox(height: 20),

            if (result.isNotEmpty)
              Expanded(child: SingleChildScrollView(child: Text(result))),
          ],
        ),
      ),
    );
  }
}