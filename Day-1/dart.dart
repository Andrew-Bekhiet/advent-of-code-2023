import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';

Future<void> main() async {
  const useExample = false;

  final inputFile =
      useExample ? File('Day-1/example-input.txt') : File('Day-1/input.txt');
  final inputLines = await inputFile.readAsLines();

  final callibrationValues =
      inputLines.map(getCallibrationValueForLine).toList();

  print(callibrationValues);

  final output = callibrationValues.sum;

  log(output.toString());
  print(output);
}

int getCallibrationValueForLine(String line) {
  final reveresedLine = line.split('').reversed.join('');

  final unitsRegex = RegExp(
    r'(\d)|((enin)|(thgie)|(neves)|(xis)|(evif)|(ruof)|(eerht)|(owt)|(eno))',
  );
  final tensRegex = RegExp(
      r'(\d)|((one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine))');

  final tensMatch = tensRegex.allMatches(line).firstOrNull;
  final unitsMatch =
      unitsRegex.allMatches(reveresedLine).firstOrNull ?? tensMatch;

  final tens = tensMatch != null
      ? int.tryParse(line.substring(tensMatch.start, tensMatch.end)) ??
          parseDigitName(line.substring(tensMatch.start, tensMatch.end))
      : 0;
  final units = unitsMatch != null
      ? int.tryParse(
              reveresedLine.substring(unitsMatch.start, unitsMatch.end)) ??
          parseDigitName(
              reveresedLine.substring(unitsMatch.start, unitsMatch.end))
      : 0;

  return tens * 10 + units;
}

int parseDigitName(String digitName) {
  switch (digitName) {
    case 'one' || 'eno':
      return 1;

    case 'two' || 'owt':
      return 2;

    case 'three' || 'eerht':
      return 3;

    case 'four' || 'ruof':
      return 4;

    case 'five' || 'evif':
      return 5;

    case 'six' || 'xis':
      return 6;

    case 'seven' || 'neves':
      return 7;

    case 'eight' || 'thgie':
      return 8;

    case 'nine' || 'enin':
      return 9;

    default:
      throw Exception('Invalid digit name: $digitName');
  }
}
