import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:collection/collection.dart';

Future<void> main() async {
  const useExample = false;

  final Stopwatch parsing = Stopwatch()..start();
  final input = await parseInput(useExample);
  parsing.stop();

  final Stopwatch part1Stopwatch = Stopwatch()..start();
  int output1 = part1(input);
  part1Stopwatch.stop();

  final Stopwatch part2Stopwatch = Stopwatch()..start();
  int output2 = part2(input);
  part2Stopwatch.stop();

  printStats(parsing, part1Stopwatch, part2Stopwatch);

  printOutputs(output1, output2);

  checkAgainstExample(useExample, output1, output2);
}

Future<List<Card>> parseInput(bool useExample) async {
  final inputFile =
      useExample ? File('Day-4/example-input.txt') : File('Day-4/input.txt');
  final inputLines = await inputFile.readAsLines();

  return inputLines.map(Card.parseLine).toList();
}

int part1(List<Card> cards) {
  final Iterable<int> countOfMatches = cards
      .map((c) => c.winningNumbers.intersection(c.availableNumbers).length);

  final Iterable<int> pointsWorth =
      countOfMatches.map((c) => pow(2, c - 1).toInt());

  return pointsWorth.sum;
}

int part2(List<Card> cards) {
  final Map<int, Set<Card>> cardsByIds = cards.groupSetsBy((c) => c.id);
  final Map<int, Set<int>> cardsMatches = cardsByIds.map(
    (id, card) =>
        MapEntry(id, expandCard(card.single, cards.sublist(id, cards.length))),
  );

  final Map<int, Set> cardsGraph = cardsMatches
      .map((id, edges) => MapEntry(id, expandEdges(edges, cardsMatches)));

  final int countOfEdges = cardsGraph.values.map(countEdges).sum;

  return countOfEdges + cards.length;
}

Set<int> expandCard(Card card, List<Card> trailingCards) {
  final int countOfMatches =
      card.winningNumbers.intersection(card.availableNumbers).length;

  return trailingCards.sublist(0, countOfMatches).map((c) => c.id).toSet();
}

Set expandEdges(Set<int> copies, Map<int, Set<int>> original) {
  return copies.map((c) => expandEdges(original[c] ?? {}, original)).toSet();
}

int countEdges(Set set) {
  return set.whereType<Set>().map(countEdges).sum + set.length;
}

void printStats(
    Stopwatch parsing, Stopwatch part1Stopwatch, Stopwatch part2Stopwatch) {
  print('Parsing took ${parsing.elapsedMilliseconds}ms');
  print('Part 1 took ${part1Stopwatch.elapsedMilliseconds}ms');
  print('Part 2 took ${part2Stopwatch.elapsedMilliseconds}ms');
}

void printOutputs(int output1, int output2) {
  log(output1.toString());
  print(output1);

  log(output2.toString());
  print(output2);
}

void checkAgainstExample(bool useExample, int output1, int output2) {
  if (!useExample) return;

  const expectedOutput1 = 13;
  const expectedOutput2 = 30;

  assert(output1 == expectedOutput1);
  assert(output2 == expectedOutput2);
}

class Card {
  int id;
  Set<int> winningNumbers;
  Set<int> availableNumbers;

  Card(
      {required this.id,
      required this.winningNumbers,
      required this.availableNumbers});

  factory Card.parseLine(String line) {
    final [idString, numbersString] = line.split(':');

    final id = int.parse(idString.replaceAll('Card ', '').trim());

    final [winningNumbersString, availableNumbersString] =
        numbersString.split('|');

    final winningNumbers = winningNumbersString
        .split(' ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toSet();
    final availableNumbers = availableNumbersString
        .split(' ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toSet();

    return Card(
      id: id,
      winningNumbers: winningNumbers,
      availableNumbers: availableNumbers,
    );
  }
}
