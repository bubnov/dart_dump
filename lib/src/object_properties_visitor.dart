import 'package:equatable/equatable.dart';

abstract class DumpTypeProvider {
  const DumpTypeProvider();
  String dumpType();
}

abstract class DumpPropertyProvider {
  const DumpPropertyProvider();
  Map<String, dynamic> dumpPropertyMap();
}

class ObjectPropertyVisitor {
  const ObjectPropertyVisitor(Object? object) : _object = object;

  final Object? _object;

  Iterable<ObjectProperty> get properties sync* {
    if (_object == null) return;

    Map<String, dynamic> props;
    if (_object is DumpPropertyProvider) {
      props = (_object as DumpPropertyProvider).dumpPropertyMap();
    } else {
      try {
        props = (_object as dynamic).dumpPropertyMap();
      } on NoSuchMethodError {
        props = {};
      }
    }

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
