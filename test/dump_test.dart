import 'package:dart_dump/dart_dump.dart';
import 'package:test/test.dart';

enum SimpleEnum { one }

class Empty {}

class Parent with DumpPropertyProvider {
  Parent({this.child});

  Object? child;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'child': child,
    };
  }
}

class Id with DumpPropertyProvider {
  Id({required this.id});

  final String id;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
    };
  }
}

class Value with DumpPropertyProvider {
  Value({required this.value});

  final String value;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
    };
  }
}

class Bla with DumpPropertyProvider {
  Bla({required this.dict});

  final Map<Id, Value> dict;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dict': dict,
    };
  }
}

class Foo with DumpPropertyProvider {
  Foo({
    required this.bla,
    required this.string,
    this.optionalString,
    required this.integer,
    this.optionalInteger,
    required this.list,
    required this.dict,
  });

  final Bla bla;
  final String string;
  final String? optionalString;
  final int integer;
  final int? optionalInteger;
  final List<dynamic> list;
  final Map<String, dynamic> dict;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bla': bla,
      'string': string,
      'optionalString': optionalString,
      'integer': integer,
      'optionalInteger': optionalInteger,
      'list': list,
      'dict': dict,
    };
  }
}

class Container with DumpPropertyProvider {
  const Container({required this.child});

  final Object child;

  @override
  Map<String, dynamic> toMap() => {'child': child};

  @override
  bool operator ==(covariant Container other) {
    if (identical(this, other)) return true;
    return other.child == child;
  }

  @override
  int get hashCode => child.hashCode;
}

void main() {
  group('object to node', () {
    test('type', () {
      const obj = String;
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const ValueNode(String),
      );
    });

    test('null', () {
      const String? obj = null;
      final dmp = objectToNode(obj);
      expect(
        dmp,
        NullNode(),
      );
    });

    test('string', () {
      const obj = 'string';
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const StringNode('string'),
      );
    });

    test('enum', () {
      const obj = SimpleEnum.one;
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const EnumNode(SimpleEnum.one),
      );
    });

    test('class', () {
      final obj = Parent(child: Empty());
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const ClassNode(
          name: 'Parent',
          values: [
            PairNode(
              key: ValueNode('child'),
              value: ClassNode(name: 'Empty'),
              last: true,
            ),
          ],
        ),
      );
    });

    test('recursion', () {
      final obj = Parent();
      obj.child = obj;
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const ClassNode(
          name: 'Parent',
          values: [
            PairNode(
              key: ValueNode('child'),
              value: RecursionNode(name: 'Parent'),
              last: true,
            ),
          ],
        ),
      );
    });

    test('list', () {
      final obj = [1, 2, 3];
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const ListNode(
          values: [
            PairNode(key: ListIndexNode(index: 0), value: ValueNode(1)),
            PairNode(key: ListIndexNode(index: 1), value: ValueNode(2)),
            PairNode(
                key: ListIndexNode(index: 2), value: ValueNode(3), last: true),
          ],
        ),
      );
    });

    test('map', () {
      final obj = {
        1: {
          'key': 'value',
        },
      };
      final dmp = objectToNode(obj);
      expect(
        dmp,
        const MapNode(
          values: [
            PairNode(
              key: ValueNode(1),
              value: MapNode(
                values: [
                  PairNode(
                    key: StringNode('key'),
                    value: StringNode('value'),
                    last: true,
                  )
                ],
              ),
              last: true,
            ),
          ],
        ),
      );
    });
  });

  group('dump', () {
    test('null', () {
      Object? obj;
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'null',
      ]);
    });

    test('type', () {
      const obj = String;
      final dmp = dumpStrings(obj).toList();
      //print(dump(obj));
      expect(dmp, [
        'String',
      ]);
    });

    test('string', () {
      const obj = 'string';
      final config = const DumpConfig().copyWith(
        nodeFormatters: {
          StringNode: const StringNodeFormatter(
            quote: '~',
          ),
        },
      );
      final dmp = dumpStrings(obj, config: config).toList();
      // print(dump(obj, config: config));
      expect(dmp, [
        '~string~',
      ]);
    });

    test('int', () {
      const obj = 123456;
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '123456',
      ]);
    });

    test('double', () {
      const obj = 123456.789;
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '123456.789',
      ]);
    });

    test('enum (hide type)', () {
      const obj = SimpleEnum.one;
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '.one',
      ]);
    });

    test('enum (with type)', () {
      const obj = SimpleEnum.one;
      final config = const DumpConfig().copyWith(
        nodeFormatters: {
          EnumNode: const EnumNodeFormatter(hideType: false),
        },
      );
      final dmp = dumpStrings(obj, config: config).toList();
      // print(dump(obj, config: config));
      expect(dmp, [
        'SimpleEnum.one',
      ]);
    });

    test('class', () {
      final obj = Parent(child: Parent(child: Empty()));
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Parent(',
        '  child: Parent(',
        '    child: Empty()',
        '  )',
        ')',
      ]);
    });

    test('class with list', () {
      final obj = Parent(
        child: [1, 2, 3],
      );
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Parent(',
        '  child: [',
        '    [0]: 1,',
        '    [1]: 2,',
        '    [2]: 3',
        '  ]',
        ')',
      ]);
    });

    test('class with map', () {
      final obj = Parent(child: {
        1: 1,
        2: {
          'key': 'value',
          'int': 1,
        },
      });
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Parent(',
        '  child: {',
        '    1: 1,',
        '    2: {',
        '      \'int\': 1,',
        '      \'key\': \'value\'',
        '    }',
        '  }',
        ')',
      ]);
    });

    test('list', () {
      final obj = [1, 2, 3];
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '[',
        '  [0]: 1,',
        '  [1]: 2,',
        '  [2]: 3',
        ']',
      ]);
    });

    test('list with list', () {
      final obj = [
        1,
        [2, 3],
        4
      ];
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '[',
        '  [0]: 1,',
        '  [1]: [',
        '    [0]: 2,',
        '    [1]: 3',
        '  ],',
        '  [2]: 4',
        ']',
      ]);
    });

    test('map', () {
      final obj = {
        'key': 'value',
        'int': 1,
      };
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '{',
        '  \'int\': 1,',
        '  \'key\': \'value\'',
        '}',
      ]);
    });

    test('map with map', () {
      final obj = {
        'key': 'value',
        'int': 1,
        'map': {
          1: 1,
          2: 2,
        },
        'string': 'string',
      };
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        '{',
        '  \'int\': 1,',
        '  \'key\': \'value\',',
        '  \'map\': {',
        '    1: 1,',
        '    2: 2',
        '  },',
        '  \'string\': \'string\'',
        '}',
      ]);
    });

    test('class with complex structure', () {
      final obj = Foo(
        bla: Bla(dict: {
          Id(id: '00000000-0000-0000-0000-000000000000'): Value(value: 'value')
        }),
        string: 'string',
        integer: 42,
        optionalInteger: 13,
        list: [1, 2],
        dict: {
          'one': 1,
          'two': 2,
          'dict': {
            1: 1,
            2: 2,
          },
          'array': [
            'one',
            'two',
          ],
        },
      );
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Foo(',
        '  bla: Bla(',
        '    dict: {',
        '      Id(',
        '        id: \'00000000-0000-0000-0000-000000000000\'',
        '      ): Value(',
        '        value: \'value\'',
        '      )',
        '    }',
        '  ),',
        '  dict: {',
        '    \'array\': [',
        '      [0]: \'one\',',
        '      [1]: \'two\'',
        '    ],',
        '    \'dict\': {',
        '      1: 1,',
        '      2: 2',
        '    },',
        '    \'one\': 1,',
        '    \'two\': 2',
        '  },',
        '  integer: 42,',
        '  list: [',
        '    [0]: 1,',
        '    [1]: 2',
        '  ],',
        '  optionalInteger: 13,',
        '  optionalString: null,',
        '  string: \'string\'',
        ')',
      ]);
    });

    test('recursion', () {
      final obj = Parent();
      obj.child = obj;
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Parent(',
        '  child: 🔴 Parent(...)',
        ')',
      ]);
    });

    test('recursion: parent.hashCode == child.hashCode', () {
      final obj = Container(child: Empty());
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'Container(',
        '  child: Empty()',
        ')',
      ]);
    });

    test('lines', () {
      const obj = LinesNode(lines: ['one', 'two', '3']);
      final dmp = dumpStrings(obj).toList();
      // print(dump(obj));
      expect(dmp, [
        'one',
        'two',
        '3',
      ]);
    });
  });
}
