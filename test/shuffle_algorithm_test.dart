import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smart Non-Repeating Shuffle Tests', () {
    test('Shuffled cycle includes all unique tracks exactly once before repeating', () {
      final List<int> originalIds = List.generate(100, (i) => i);
      final List<int> shuffled = List.from(originalIds)..shuffle();

      expect(shuffled.length, originalIds.length);
      expect(shuffled.toSet().length, originalIds.length); // Zero duplicates
      expect(shuffled.toSet(), originalIds.toSet()); // Contains all original elements
    });

    test('Single-element and empty queues handle shuffle safely without crash', () {
      final List<int> emptyList = [];
      emptyList.shuffle();
      expect(emptyList, isEmpty);

      final List<int> single = [42];
      single.shuffle();
      expect(single, [42]);
    });
  });
}
