import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/card_model.dart';
import '../models/question_model.dart';
import '../screens/questionnaire_page2.dart';
import '../widgets/question_widget.dart';

class DhwaniApp_QuestionnairePage extends StatefulWidget {
  const DhwaniApp_QuestionnairePage({super.key});

  @override
  State<DhwaniApp_QuestionnairePage> createState() => DhwaniApp_QuestionnairePageState();
}

class DhwaniApp_QuestionnairePageState extends State<DhwaniApp_QuestionnairePage> {
  List<Question> questions = [];
  List<List<String>> selectedAnswers = [];
  Map<String, String> selectedAnswersMap = {};

  late Box<QuestionModel> questionBox;
  late Box answersBox;
  late Box<CardModel> cardBox;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCardDataToHiveAndUpdate() async {
    final jsonString = await DefaultAssetBundle.of(context).loadString('assets/dataFiles/card_Data.json');
    final jsonData = jsonDecode(jsonString);
    // print(jsonData);

    cardBox = Hive.box('cards_HiveBox');
    cardBox.clear();

    // load card details to database - debug
    for (final cardData in jsonData) {
      // instead of below two lines, do this - if cardTitle in List<List<String>> selectedAnswers, then set a boolean variable to true
      final cardTitle = cardData['title'];
      final isFav = selectedAnswers.any((answer) => answer.contains(cardTitle)) ? true : false;

      final card = CardModel(
        imagePath: cardData['imagePath'],
        title: cardTitle,
        isFav: isFav,
        description: cardData['description'],
        malluDescription: cardData['malluDescription'],
        tags: List<String>.from(cardData['tags']),
        clickCount: isFav ? 5 : 0,
        emotion: ["null"],
      );
      cardBox.add(card);
    }

    // debugging
    // if (cardBox.isEmpty) { print('The box is empty'); }
    // for (var key in cardBox.keys) {
    //   var card = cardBox.get(key) as CardModel;
    //   print('Card $key:');
    //   print('Image Path: ${card.imagePath}');
    //   print('Title: ${card.title}');
    //   print('Is Favorite: ${card.isFav}');
    //   print('Description: ${card.description}');
    //   print('Mallu Description: ${card.malluDescription}');
    //   print('Tags: ${card.tags}');
    //   print('Click Count: ${card.clickCount}');
    //   print('-------------------');
    // }
  }

  Future<void> _loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/dataFiles/questionnaire_Data.json');
    final jsonData = jsonDecode(jsonString);
    // print((jsonData[0])['questionText']);

    // final questionBox = await Hive.openBox<Question>('questions');
    questionBox = Hive.box('questions_HiveBox');
    questionBox.clear(); // clear all data in questionBox

    for (final questionData in jsonData) {
      final questionModelTyped = QuestionModel(
          questionText: questionData['questionText'],
          options: List<String>.from(questionData['options']));

      // final question = Question(
      //   questionModelTyped.questionText,
      //   questionModelTyped.options,
      // );

      questionBox.add(questionModelTyped); // added using index as key - automatically
    }

    setState(() {
      questions = questionBox.values.map((dynamic questionModelTyped) {
        return Question(
          questionModelTyped.questionText,
          questionModelTyped.options,
        );
      }).toList();
      selectedAnswers = List<List<String>>.filled(questions.length, []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Questionnaire")),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (BuildContext context, int index) {
          return QuestionWidget(
            // modifications needed here
            question: questions[index],
            onAnswerSelected: (List<String> selectedOptions) {
              debugPrint(selectedOptions.toString());
              selectedAnswers[index] = selectedOptions;
              selectedAnswersMap[questions[index].questionText] = selectedOptions.isNotEmpty ? selectedOptions[0] : '';
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Load card data to Hive and set isFav based on selected answers
          // print('Selected Answers Map: $selectedAnswersMap'); // debug
          await _loadCardDataToHiveAndUpdate();

          // Print contents of cardBox
          // for (var i = 0; i < cardBox.length; i++) {
          //   final card = cardBox.getAt(i) as CardModel;
          //   print('Card $i: ${card.title}, IsFav: ${card.isFav}');
          // }

          // Redirect to Home_Page
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DhwaniApp_QuestionnairePage2()));
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
