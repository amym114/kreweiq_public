class QuizQuestion {
  final String text;
  final List<String> answers;
  final String correctAnswer; // Stores the correct answer

  const QuizQuestion(this.text, this.answers, this.correctAnswer) // The first answer is the correct one

  void List<String> getShuffledAnswers() {
    final shuffleList = List.of(answers);
    shuffleList.shuffle();
    return shuffleList;
  }
}
