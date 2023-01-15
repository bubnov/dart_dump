import 'package:equatable/equatable.dart';

mixin DumpTypeProvider {
  String dumpType() => '$runtimeType';
}

mixin DumpPropertyProvider {
  Map<String, dynamic> toMap() => {};
}

class ObjectPropertyVisitor {
  const ObjectPropertyVisitor(Object? object) : _object = object;

  final Object? _object;

  Iterable<ObjectProperty> get properties sync* {
    if (_object == null) return;

    final props = _object is DumpPropertyProvider
        ? (_object as DumpPropertyProvider).toMap()
        : {};

    // final props = _object is Dumpable ? (_object as Dumpable).propertyMap() : {};
    if (props.isNotEmpty) {
      final propsName = props.keys.toList()..sort();
      for (final propName in propsName) {
        yield ObjectProperty(
          name: propName,
          value: props[propName],
        );
      }
    }
  }
}

class ObjectProperty extends Equatable {
  const ObjectProperty({
    required this.name,
    required this.value,
  });

  final Object name;
  final Object? value;

  @override
  List<Object?> get props => [name, value];
}
