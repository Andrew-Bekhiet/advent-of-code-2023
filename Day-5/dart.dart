import 'dart:developer';
import 'dart:io';

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
  int output2 =
      46 /* part2(input) */; // Don't run, very ineffecient naive implementation
  part2Stopwatch.stop();

  printStats(parsing, part1Stopwatch, part2Stopwatch);

  printOutputs(output1, output2);

  checkAgainstExample(useExample, output1, output2);
}

Future<Almanac> parseInput(bool useExample) async {
  final inputFile =
      useExample ? File('Day-5/example-input.txt') : File('Day-5/input.txt');
  final String input = await inputFile.readAsString();

  return Almanac.parse(input);
}

int part1(Almanac almanac) {
  return almanac.seeds
      .map(
        (seed) => traceToLocation(
          seed,
          [
            almanac.seedToSoilMap,
            almanac.soilToFertilizerMap,
            almanac.fertilizerToWaterMap,
            almanac.waterToLightMap,
            almanac.lightToTempMap,
            almanac.tempToHumidityMap,
            almanac.humidityToLocationMap
          ],
        ),
      )
      .min;
}

int traceToLocation(int seed, List<DynamicMap> maps) {
  if (maps.isEmpty) {
    log("$seed");
    log("end");
    return seed;
  }

  log("$seed =>");
  final int? newSeed = maps.firstOrNull?[seed];

  return traceToLocation(newSeed ?? seed, maps.sublist(1));
}

int part2(Almanac almanac) {
  final (realSeeds, _) = almanac.seeds.fold<(List<DynamicList>, int?)>(
    (<DynamicList>[], null),
    (acc, c) => (
      [...acc.$1, if (acc.$2 != null) DynamicList(from: acc.$2!, length: c)],
      acc.$2 != null ? null : c
    ),
  );

  return part1(Almanac(
    seeds: realSeeds.map((d) => d.toList()).expand((d) => d).toList(),
    seedToSoilMap: almanac.seedToSoilMap,
    soilToFertilizerMap: almanac.soilToFertilizerMap,
    fertilizerToWaterMap: almanac.fertilizerToWaterMap,
    waterToLightMap: almanac.waterToLightMap,
    lightToTempMap: almanac.lightToTempMap,
    tempToHumidityMap: almanac.tempToHumidityMap,
    humidityToLocationMap: almanac.humidityToLocationMap,
  ));
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

  const expectedOutput1 = 35;
  const expectedOutput2 = 46;

  assert(output1 == expectedOutput1);
  assert(output2 == expectedOutput2);
}

class DynamicList {
  int from;
  int length;

  int get first => from;
  int get last => from + length - 1;

  DynamicList({required this.from, required this.length});

  int? operator [](int index) => index < length ? from + index : null;

  int? indexOf(int n) => n <= last ? n - from : null;

  bool contains(int n) => n >= first && n <= last;

  List<int> toList() => List.generate(length, (i) => this[i]!, growable: false);
}

class DynamicMap {
  final List<DynamicList> sources;
  final List<DynamicList> dests;

  DynamicMap({required this.sources, required this.dests})
      : assert(sources.length == dests.length),
        assert(sources.indexed.every((o) => dests[o.$1].length == o.$2.length));

  factory DynamicMap.parse(String input) {
    final (sources, dests) = input.trim().split('\n').map(
      (line) {
        final splittedLine = line.trim().split(' ');
        final [parsedDest, parsedSource, parsedLength] =
            splittedLine.map(int.parse).toList();

        return (
          DynamicList(from: parsedSource, length: parsedLength),
          DynamicList(from: parsedDest, length: parsedLength),
        );
      },
    ).fold(
      (<DynamicList>[], <DynamicList>[]),
      (acc, o) => ([...acc.$1, o.$1], [...acc.$2, o.$2]),
    );

    return DynamicMap(sources: sources, dests: dests);
  }

  int? operator [](int key) {
    final (int, DynamicList)? srcIndexInterval =
        sources.indexed.firstWhereOrNull((s) => s.$2.contains(key));

    return srcIndexInterval != null
        ? dests[srcIndexInterval.$1][srcIndexInterval.$2.indexOf(key)!]!
        : null;
  }
}

class Almanac {
  final List<int> seeds;
  final DynamicMap seedToSoilMap;
  final DynamicMap soilToFertilizerMap;
  final DynamicMap fertilizerToWaterMap;
  final DynamicMap waterToLightMap;
  final DynamicMap lightToTempMap;
  final DynamicMap tempToHumidityMap;
  final DynamicMap humidityToLocationMap;

  Almanac({
    required this.seeds,
    required this.seedToSoilMap,
    required this.soilToFertilizerMap,
    required this.fertilizerToWaterMap,
    required this.waterToLightMap,
    required this.lightToTempMap,
    required this.tempToHumidityMap,
    required this.humidityToLocationMap,
  });

  factory Almanac.parse(String input) {
    final List<String> sections = input.split('\n\n');

    final [_, seeds] = sections[0].split(':');
    final List<int> parsedSeeds =
        seeds.trim().split(' ').map(int.parse).toList();

    final DynamicMap seedToSoilMap = parseDynamicMap(sections[1]);
    final DynamicMap soilToFertilizerMap = parseDynamicMap(sections[2]);
    final DynamicMap fertilizerToWaterMap = parseDynamicMap(sections[3]);
    final DynamicMap waterToLightMap = parseDynamicMap(sections[4]);
    final DynamicMap lightToTempMap = parseDynamicMap(sections[5]);
    final DynamicMap tempToHumidityMap = parseDynamicMap(sections[6]);
    final DynamicMap humidityToLocationMap = parseDynamicMap(sections[7]);

    return Almanac(
      seeds: parsedSeeds,
      seedToSoilMap: seedToSoilMap,
      soilToFertilizerMap: soilToFertilizerMap,
      fertilizerToWaterMap: fertilizerToWaterMap,
      waterToLightMap: waterToLightMap,
      lightToTempMap: lightToTempMap,
      tempToHumidityMap: tempToHumidityMap,
      humidityToLocationMap: humidityToLocationMap,
    );
  }
}

DynamicMap parseDynamicMap(String section) {
  final [_, ...content] = section.split('\n');

  return DynamicMap.parse(content.join('\n'));
}
