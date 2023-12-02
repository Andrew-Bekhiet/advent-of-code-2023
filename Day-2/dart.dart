import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:collection/collection.dart';

Future<void> main() async {
  final input = await parseInput();

  int output = part2(input);

  log(output.toString());
  print(output);
}

int part2(List<Game> input) {
  return input.map(
    (game) {
      final minimumRequirement = game.cubesColorsCount.fold(
        (0, 0, 0),
        (acc, o) => (
          max(acc.$1, o.red.count),
          max(acc.$2, o.green.count),
          max(acc.$3, o.blue.count)
        ),
      );

      return minimumRequirement.$1 *
          minimumRequirement.$2 *
          minimumRequirement.$3;
    },
  ).sum;
}

int part1(List<Game> input) {
  final requirement = CubesColorsCount.fromList([
    CubeColorCount(color: 'red', count: 12),
    CubeColorCount(color: 'green', count: 13),
    CubeColorCount(color: 'blue', count: 14),
  ]);

  final statisfyingGames = input
      .where(
        (game) =>
            game.cubesColorsCount.every((set) => set.statisfies(requirement)),
      )
      .toList();

  print(statisfyingGames.map((game) => game.id));

  final output = statisfyingGames.map((game) => game.id).sum;
  return output;
}

Future<List<Game>> parseInput() async {
  const useExample = false;

  final inputFile =
      useExample ? File('Day-2/example-input.txt') : File('Day-2/input.txt');
  final inputLines = await inputFile.readAsLines();

  return inputLines.map(Game.parse).toList();
}

class Game {
  final int id;
  final Set<CubesColorsCount> cubesColorsCount;

  Game({required this.id, required this.cubesColorsCount});

  factory Game.parse(String line) {
    final gameIdRegex = RegExp(r'Game (\d+):');
    final cubeRegex = RegExp(r'(\d+) ((blue)|(red)|(green))');

    final idMatch = gameIdRegex.firstMatch(line)!;

    final cubesSets = line
        .substring(idMatch.end, line.length)
        .trim()
        .split(';')
        .map((s) => s.trim())
        .toList();

    final parsedCubesSets = cubesSets
        .map((s) => s.split(',').map((s) => s.trim()))
        .map(
          (s) => CubesColorsCount.fromList(s
              .map(
                (s) => CubeColorCount(
                  color: cubeRegex.firstMatch(s)!.group(2)!,
                  count: int.parse(cubeRegex.firstMatch(s)!.group(1)!),
                ),
              )
              .toList()),
        )
        .toSet();

    return Game(
      id: int.parse(idMatch.group(1)!),
      cubesColorsCount: parsedCubesSets,
    );
  }
}

class CubeColorCount {
  final String color;
  final int count;

  CubeColorCount({required this.color, required this.count});
}

class CubesColorsCount {
  CubeColorCount red;
  CubeColorCount green;
  CubeColorCount blue;

  CubesColorsCount(
      {required this.red, required this.green, required this.blue});

  factory CubesColorsCount.fromList(List<CubeColorCount> list) {
    return CubesColorsCount(
      red: list.firstWhereOrNull((c) => c.color == 'red') ??
          CubeColorCount(color: 'red', count: 0),
      green: list.firstWhereOrNull((c) => c.color == 'green') ??
          CubeColorCount(color: 'green', count: 0),
      blue: list.firstWhereOrNull((c) => c.color == 'blue') ??
          CubeColorCount(color: 'blue', count: 0),
    );
  }
}

extension on CubesColorsCount {
  bool statisfies(CubesColorsCount limit) {
    return red.count < limit.red.count &&
        green.count < limit.green.count &&
        blue.count < limit.blue.count;
  }
}
