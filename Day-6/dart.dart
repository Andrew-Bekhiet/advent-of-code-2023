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

Future<List<Race>> parseInput(bool useExample) async {
  final inputFile =
      useExample ? File('Day-6/example-input.txt') : File('Day-6/input.txt');
  final String input = await inputFile.readAsString();

  final [times, distances] = input.trim().split('\n').map((line) {
    final parts = line
        .split(':')[1]
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList();

    return parts.map(int.parse).toList();
  }).toList();

  return times.mapIndexed((i, t) => Race(distances[i], t)).toList();
}

int part1(List<Race> races) {
  final nOfSolutions = races.map((r) {
    final solutions = r.solveForHoldTime();

    if (solutions == null) return 0;

    final r1 = solutions.$1.round() - solutions.$1 == 0
        ? solutions.$1.toInt() + 1
        : solutions.$1.ceil();
    final r2 = solutions.$2.round() - solutions.$2 == 0
        ? solutions.$2.toInt() - 1
        : solutions.$2.floor();

    return (r1 - r2).abs().toInt() + 1;
  });

  return nOfSolutions.reduce((a, b) => a * b);
}

int part2(List<Race> races) {
  return part1(
    [
      races.reduce(
        (r, a) => Race(
          int.parse(r.minDistance.toString() + a.minDistance.toString()),
          int.parse(r.maxTime.toString() + a.maxTime.toString()),
        ),
      ),
    ],
  );
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

  const expectedOutput1 = 288;
  const expectedOutput2 = 71503;

  assert(output1 == expectedOutput1);
  assert(output2 == expectedOutput2);
}

class Race {
  final int minDistance;
  final int maxTime;

  Race(this.minDistance, this.maxTime);

  // -t_hold^2 + t_hold * maxTime - minDistance > 0
  (double, double)? solveForHoldTime() {
    final double a = -1;
    final double b = maxTime.toDouble();
    final double c = -minDistance.toDouble();

    final double discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return null;

    final double sqrtDiscriminant = sqrt(discriminant);

    final double t1 = (-b + sqrtDiscriminant) / (2 * a);
    final double t2 = (-b - sqrtDiscriminant) / (2 * a);

    return (t1, t2);
  }
}
