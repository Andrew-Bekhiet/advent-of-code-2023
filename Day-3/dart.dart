import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';

Future<void> main() async {
  const useExample = false;

  final input = await parseInput(useExample);

  int output1 = part1(input);
  int output2 = part2(input);

  log(output1.toString());
  print(output1);

  log(output2.toString());
  print(output2);

  if (useExample) {
    const expectedOutput1 = 4361;
    const expectedOutput2 = 467835;

    assert(output1 == expectedOutput1);
    assert(output2 == expectedOutput2);
  }
}

int part2(List<String> input) {
  final gearRatioSymbolRegex = RegExp(r'(\*)');
  final List<List<int>> symbolsIndcies = input
      .map((l) =>
          gearRatioSymbolRegex.allMatches(l).map((m) => m.start).toList())
      .toList();

  return symbolsIndcies
      .mapIndexed(
        (i, l) {
          return l
              .map(
                (j) => input.getAdjacentNumbers(i, j),
              )
              .where((e) => e.length == 2)
              .map((e) => e[0] * e[1])
              .map(dump);
        },
      )
      .expand((e) => e)
      .toList()
      .map(dump)
      .sum;
}

int part1(List<String> input) {
  final symbolRegex = RegExp(r'([^\d\.])');
  final List<List<int>> symbolsIndcies = input
      .map((l) => symbolRegex.allMatches(l).map((m) => m.start).toList())
      .toList();

  return symbolsIndcies
      .mapIndexed(
        (i, l) {
          log(i.toString());
          return l
              .map(
                (j) => input.getAdjacentNumbers(i, j),
              )
              .map(dump)
              .expand((e) => e);
        },
      )
      .expand((e) => e)
      .toList()
      .map(dump)
      .sum;
}

Future<List<String>> parseInput(bool useExample) async {
  final inputFile =
      useExample ? File('Day-3/example-input.txt') : File('Day-3/input.txt');
  final inputLines = await inputFile.readAsLines();

  return inputLines.toList();
}

extension IsSymbol on String {
  bool get isSymbol => this != '.' && !this.isNumber;
}

extension IsNumber on String {
  bool get isNumber => int.tryParse(this) != null;
}

extension ScanNumber on String {
  int? scanNumberAtMiddle(int i) {
    if (!this[i].isNumber) return null;

    final String number = [
      this
          .split('')
          .sublist(0, i)
          .reversed
          .takeWhile((c) => c.isNumber)
          .toList()
          .reversed
          .join(''),
      this
          .split('')
          .sublist(i, this.length)
          .takeWhile((c) => c.isNumber)
          .join(''),
    ].where((e) => e.isNotEmpty).join('');

    return int.tryParse(number);
  }
}

extension AdjacentNumbers on List<String> {
  List<int> getAdjacentNumbers(int i, int j) {
    final List<int> horizontal = _scanLine(this[i], j);
    final List<int> verticalAndDiagonals = _scanYAndDiagonals(i, j);

    return [...horizontal, ...verticalAndDiagonals];
  }

  List<int> _scanLine(String line, int symbolIndex) {
    if (line[symbolIndex + 1].isNumber || line[symbolIndex - 1].isNumber) {
      final String left = line.substring(0, symbolIndex);
      final String right = line.substring(symbolIndex + 1, line.length);

      final leftNumber = left.scanNumberAtMiddle(left.length - 1);
      final rightNumber = right.scanNumberAtMiddle(0);

      return [leftNumber, rightNumber].whereNotNull().toList();
    }

    return [];
  }

  List<int> _scanYAndDiagonals(int i, int j) {
    final String top = i != 0 ? this[i - 1] : '';
    final String bottom = i + 1 <= length ? this[i + 1] : '';

    if (top[j - 1].isNumber ||
        top[j].isNumber ||
        top[j + 1].isNumber ||
        bottom[j - 1].isNumber ||
        bottom[j].isNumber ||
        bottom[j + 1].isNumber) {
      return [
        ...{
          top.scanNumberAtMiddle(j - 1),
          top.scanNumberAtMiddle(j),
          top.scanNumberAtMiddle(j + 1)
        },
        ...{
          bottom.scanNumberAtMiddle(j - 1),
          bottom.scanNumberAtMiddle(j),
          bottom.scanNumberAtMiddle(j + 1),
        }
      ].whereNotNull().toList();
    }

    return [];
  }
}

T dump<T>(T obj) {
  log(obj.toString());
  return obj;
}
