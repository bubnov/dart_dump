import 'package:dart_dump/dart_dump.dart';
import 'package:test/test.dart';

void main() {
  test('object visitor provides properties', () {
    expect(
      ObjectPropertyVisitor(
        Foo(
          string: 'string',
          integer: 1,
        ),
      ).properties.toList(),
      const [
        ObjectProperty(name: 'integer', value: 1),
        ObjectProperty(name: 'string', value: 'string'),
      ],
    );
  });

  group('optional properties', () {
    test('optional is null', () {
      final foo = FooWithOptional();
      final fooProps = ObjectPropertyVisitor(foo).properties.toList();
      expect(
        fooProps,
        [
          const ObjectProperty(name: 'optionalString', value: null),
        ],
      );
    });

    test('optional isn\'t null', () {
      final foo = FooWithOptional(optionalString: 'string');
      final fooProps = ObjectPropertyVisitor(foo).properties.toList();
      expect(
        fooProps,
        [
          const ObjectProperty(name: 'optionalString', value: 'string'),
        ],
      );
    });
  });
}

class FooWithOptional extends Dumpable {
  FooWithOptional({
    this.optionalString,
  });

  final String? optionalString;

  @override
  Map<String, dynamic> propertyMap() {
    return <String, dynamic>{
      'optionalString': optionalString,
    };
  }
}

class Foo extends Dumpable {
  Foo({
    required this.string,
    required this.integer,
  });

  final String string;
  final int integer;

  @override
  Map<String, dynamic> propertyMap() {
    return <String, dynamic>{
      'string': string,
      'integer': integer,
    };
  }
}
