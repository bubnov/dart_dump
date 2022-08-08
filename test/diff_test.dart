import 'package:dart_dump/dart_dump.dart';
import 'package:test/test.dart';

import 'dump_test.dart';

final diffConfig = const DiffConfig().copyWith(
    format: const DiffFormat(formattingAllowed: false));

void main() {
  test('equal', () {
    const obj1 = true;
    const obj2 = true;
    final result = diffStrings(obj1, obj2).toList();
    expect(result, []);
  });

  group('different', () {
    test('same types', () {
      const obj1 = 1.12;
      const obj2 = 2;
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '- 1.12',
        '+ 2',
      ]);
    });

    test('mixed types: long to short', () {
      const obj1 = [1, 2, 3];
      const obj2 = 'string';
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '- [',
        '-   [0]: 1,',
        '-   [1]: 2,',
        '-   [2]: 3',
        '- ]',
        '+ \'string\'',
      ]);
    });

    test('mixed types: short to long', () {
      const obj1 = 'string';
      const obj2 = [1, 2, 3];
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '- \'string\'',
        '+ [',
        '+   [0]: 1,',
        '+   [1]: 2,',
        '+   [2]: 3',
        '+ ]',
      ]);
    });

    test('arrays: one-dimensional', () {
      final obj1 = [1, 2, 3, 4];
      final obj2 = [2, 4, 5];
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  [',
        '-   [0]: 1,',
        '+   [0]: 2,',
        '-   [1]: 2,',
        '+   [1]: 4,',
        '-   [2]: 3,',
        '+   [2]: 5',
        '-   [3]: 4',
        '  ]',
      ]);
    });

    test('arrays: one-dimensional, diff types', () {
      final obj1 = [1, 2, 3, 4];
      final obj2 = ['2', '4', '5'];
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      print(diff(obj1, obj2));
      expect(result, [
        '  [',
        '-   [0]: 1,',
        '+   [0]: \'2\',',
        '-   [1]: 2,',
        '+   [1]: \'4\',',
        '-   [2]: 3,',
        '+   [2]: \'5\'',
        '-   [3]: 4',
        '  ]',
      ]);
    });

    test('arrays: multi-dimensional', () {
      final obj1 = [
        1,
        [2, 3],
        [4],
        5
      ];
      final obj2 = [
        1,
        2,
        [3, 4],
        [5],
        6
      ];
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  [',
        '    [0]: 1,',
        '-   [1]: [',
        '-     [0]: 2,',
        '-     [1]: 3',
        '-   ],',
        '+   [1]: 2,',
        '    [2]: [',
        '-     [0]: 4',
        '+     [0]: 3,',
        '+     [1]: 4',
        '    ],',
        '-   [3]: 5',
        '+   [3]: [',
        '+     [0]: 5',
        '+   ],',
        '+   [4]: 6',
        '  ]',
      ]);
    });

    test('maps', () {
      final obj1 = {1: 1, 2: 2};
      final obj2 = {1: 'one', 3: 'three'};
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  {',
        '-   1: 1,',
        '+   1: \'one\',',
        '-   2: 2',
        '+   3: \'three\'',
        '  }',
      ]);
    });

    test('maps with maps', () {
      final obj1 = {
        '1': 1,
        '2': {2: 2},
        '3': {3: 3},
        '4': 4
      };
      final obj2 = {
        '1': 1,
        '2': 2,
        '3': {'name': 'three', 'value': 3},
        '4': {4: 4}
      };
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  {',
        '    \'1\': 1,',
        '-   \'2\': {',
        '-     2: 2',
        '-   },',
        '+   \'2\': 2,',
        '    \'3\': {',
        '-     3: 3',
        '+     \'name\': \'three\',',
        '+     \'value\': 3',
        '    },',
        '-   \'4\': 4',
        '+   \'4\': {',
        '+     4: 4',
        '+   }',
        '  }',
      ]);
    });

    test('classes', () {
      final obj1 = Parent();
      final obj2 = Parent(child: 'string');
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  Parent(',
        '-   child: null',
        '+   child: \'string\'',
        '  )',
      ]);
    });

    test('classes with classes', () {
      final obj1 = Parent(
        child: [1, 2],
      );
      final obj2 = Parent(
        child: Parent(
          child: {'name': 'value'},
        ),
      );
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  Parent(',
        '-   child: [',
        '-     [0]: 1,',
        '-     [1]: 2',
        '-   ]',
        '+   child: Parent(',
        '+     child: {',
        '+       \'name\': \'value\'',
        '+     }',
        '+   )',
        '  )',
      ]);
    });

    test('classes with classes, deep change', () {
      final obj1 = Parent(
        child: Parent(
          child: {'name': 'value'},
        ),
      );
      final obj2 = Parent(
        child: Parent(
          child: {1: 1},
        ),
      );
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  Parent(',
        '    child: Parent(',
        '      child: {',
        '-       \'name\': \'value\'',
        '+       1: 1',
        '      }',
        '    )',
        '  )',
      ]);
    });

    test('unchanged folding: enabled', () {
      final obj1 = [
        1,
        2,
        3,
        {1: 1, 2: 2, 3: 3, 4: 4, 5: 5},
        5,
      ];
      final obj2 = [
        1,
        2,
        3,
        {1: 1, 2: 2, 3: 33, 4: 4, 5: 5},
        5,
      ];
      final result = diffStrings(obj1, obj2, diffConfig: diffConfig).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  [',
        '    … (3 unchanged),',
        '    [3]: {',
        '      … (2 unchanged),',
        '-     3: 3,',
        '+     3: 33,',
        '      … (2 unchanged)',
        '    },',
        '    [4]: 5',
        '  ]',
      ]);
    });

    test('unchanged folding: disabled', () {
      final obj1 = [
        1,
        2,
        3,
        {1: 1, 2: 2, 3: 3, 4: 4, 5: 5},
        5,
      ];
      final obj2 = [
        1,
        2,
        3,
        {1: 1, 2: 2, 3: 33, 4: 4, 5: 5},
        5,
      ];
      final result = diffStrings(
        obj1,
        obj2,
        diffConfig: diffConfig.copyWith(foldUnchanged: false),
      ).toList();
      // print(diff(obj1, obj2));
      expect(result, [
        '  [',
        '    [0]: 1,',
        '    [1]: 2,',
        '    [2]: 3,',
        '    [3]: {',
        '      1: 1,',
        '      2: 2,',
        '-     3: 3,',
        '+     3: 33,',
        '      4: 4,',
        '      5: 5',
        '    },',
        '    [4]: 5',
        '  ]',
      ]);
    });
  });
}
