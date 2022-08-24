import 'package:equatable/equatable.dart';

import 'object_properties_visitor.dart';

abstract class Node extends Equatable {
  const Node();

  @override
  List<Object?> get props => [];
}

class NullNode extends Node {}

class ValueNode extends Node {
  const ValueNode(this.value);

  final Object value;

  @override
  List<Object?> get props => [...super.props, value];
}

class StringNode extends Node {
  const StringNode(this.value);

  final String value;

  @override
  List<Object?> get props => [...super.props, value];
}

class EnumNode extends Node {
  const EnumNode(this.value);

  final Enum value;

  @override
  List<Object?> get props => [...super.props, value];
}

class RecursionNode extends Node {
  const RecursionNode({required this.name});

  final String name;

  @override
  List<Object?> get props => [...super.props, name];
}

class GroupNode extends Node {
  const GroupNode({
    this.name,
    this.values = const [],
  });

  final String? name;
  final List<PairNode> values;

  @override
  List<Object?> get props => [...super.props, name, values];
}

class ClassNode extends GroupNode {
  const ClassNode({super.name, super.values});
}

class ListNode extends GroupNode {
  const ListNode({super.name, super.values});
}

class MapNode extends GroupNode {
  const MapNode({super.name, super.values});
}

class ListIndexNode extends Node {
  const ListIndexNode({
    required this.index,
  });

  final int index;

  @override
  List<Object?> get props => [...super.props, index];
}

class LinesNode extends Node {
  const LinesNode({
    this.lines = const [],
    this.last = false,
  });

  final List<String> lines;
  final bool last;

  @override
  List<Object?> get props => [...super.props, lines, last];
}

class PairNode extends Node {
  const PairNode({
    required this.key,
    required this.value,
    this.last = false,
  });

  final Node key;
  final Node value;
  final bool last;

  @override
  List<Object?> get props => [...super.props, key, value, last];
}

class _ObjectToNodeContext {
  _ObjectToNodeContext();

  final Set<int> _processedObjectHashes = {};

  bool isObjectProcessed(Object object) {
    return _processedObjectHashes.contains(object.hashCode);
  }

  didProcessObject(Object object) {
    _processedObjectHashes.add(object.hashCode);
  }
}

Node objectToNode(Object? object) {
  final context = _ObjectToNodeContext();
  return _objectToNode(object, context);
}

Node _objectToNode(
  Object? object,
  _ObjectToNodeContext context,
) {
  if (object == null) {
    return NullNode();
  }

  if (object is Type || object is int || object is double || object is bool) {
    return ValueNode(object);
  }

  if (object is String) {
    return StringNode(object);
  }

  if (object is Enum) {
    return EnumNode(object);
  }

  if (object is List) {
    List<PairNode> listValueNodes = [];
    for (var i = 0; i < object.length; i++) {
      listValueNodes.add(
        PairNode(
          key: ListIndexNode(index: i),
          value: _objectToNode(object[i], context),
          last: i == object.length - 1,
        ),
      );
    }
    return ListNode(values: listValueNodes);
  }

  if (object is Map) {
    List<PairNode> values = [];
    final keys = object.keys.toList();
    keys.sort();
    for (final key in keys) {
      values.add(
        PairNode(
          key: _objectToNode(key, context),
          value: _objectToNode(object[key], context),
          last: key == keys.last,
        ),
      );
    }
    return MapNode(values: values);
  }

  if (context.isObjectProcessed(object)) {
    return RecursionNode(name: object.runtimeType.toString());
  }

  context.didProcessObject(object);

  final props = ObjectPropertyVisitor(object).properties.toList();
  List<PairNode> propertyNodes = [];
  for (var i = 0; i < props.length; i++) {
    final prop = props[i];
    propertyNodes.add(
      PairNode(
        key: ValueNode(prop.name),
        value: _objectToNode(prop.value, context),
        last: i == props.length - 1,
      ),
    );
  }

  String className;
  if (object is DumpTypeProvider) {
    className = object.dumpType();
  } else {
    try {
      className = (object as dynamic).dumpType();
    } on NoSuchMethodError catch (_) {
      className = object.runtimeType.toString();
    }
  }

  return ClassNode(name: className, values: propertyNodes);
}

abstract class NodeFormatter {
  const NodeFormatter();

  List<String> format(Node node, DumpConfig config);
}

class NullNodeFormatter extends NodeFormatter {
  const NullNodeFormatter();

  @override
  List<String> format(Node node, DumpConfig config) {
    return [
      'null',
    ];
  }
}

class ValueNodeFormatter extends NodeFormatter {
  const ValueNodeFormatter();

  @override
  List<String> format(covariant ValueNode node, DumpConfig config) {
    return [
      node.value.toString(),
    ];
  }
}

class StringNodeFormatter extends NodeFormatter {
  const StringNodeFormatter({
    this.quote = '\'',
  });

  final String quote;

  @override
  List<String> format(covariant StringNode node, DumpConfig config) {
    return [
      '$quote${node.value}$quote',
    ];
  }
}

class EnumNodeFormatter extends NodeFormatter {
  const EnumNodeFormatter({
    this.hideType = true,
    this.separator = '.',
  });

  final bool hideType;
  final String separator;

  @override
  List<String> format(covariant EnumNode node, DumpConfig config) {
    final parts = node.value.toString().split(separator);
    final type = hideType ? '' : parts.first;
    final name = parts.last;
    return [
      '$type$separator$name',
    ];
  }
}

class GroupNodeFormatter extends NodeFormatter {
  const GroupNodeFormatter({
    required this.startBracket,
    required this.endBracket,
  });

  final String startBracket;
  final String endBracket;

  @override
  List<String> format(covariant GroupNode node, DumpConfig config) {
    List<String> allValueLines = [];
    for (var i = 0; i < node.values.length; i++) {
      final valueLines = dumpStrings(
        node.values[i],
        config: config.copyWith(
          level: config.level + 1,
        ),
      );
      allValueLines.addAll(valueLines);
    }

    return [
      '${node.name ?? ''}'
          '$startBracket'
          '${allValueLines.isEmpty ? endBracket : ''}',
      ...allValueLines,
      if (allValueLines.isNotEmpty)
        '${config.spacer * config.level}$endBracket',
    ];
  }
}

class PairNodeFormatter extends NodeFormatter {
  const PairNodeFormatter({
    this.separator = ': ',
    this.valuesSeparator = ',',
  });

  final String separator;
  final String valuesSeparator;

  @override
  List<String> format(covariant PairNode node, DumpConfig config) {
    final indent = config.spacer * config.level;

    final keyLines = dumpStrings(
      node.key,
      config: config,
    ).toList();

    final valueLines = dumpStrings(
      node.value,
      config: config,
    ).toList();

    List<String> lines = [];

    for (var i = 0; i < keyLines.length - 1; i++) {
      lines.add(
        '${i == 0 ? indent : ''}'
        '${keyLines[i]}',
      );
    }

    lines.add(
      '${keyLines.length == 1 ? indent : ''}'
      '${keyLines.last}'
      '$separator'
      '${valueLines.first}'
      '${valueLines.length == 1 && !node.last ? valuesSeparator : ''}',
    );

    for (var i = 1; i < valueLines.length; i++) {
      lines.add(
        '${valueLines[i]}'
        '${i == valueLines.length - 1 && !node.last ? valuesSeparator : ''}',
      );
    }

    return lines;
  }
}

class RecursionNodeFormatter extends NodeFormatter {
  const RecursionNodeFormatter({
    this.prefix = '🔴 ',
    this.propertiesStub = '...',
    this.startBracket = '(',
    this.endBracket = ')',
  });

  final String prefix;
  final String propertiesStub;
  final String startBracket;
  final String endBracket;

  @override
  List<String> format(covariant RecursionNode node, DumpConfig config) {
    return [
      '$prefix'
          '${node.name}'
          '$startBracket'
          '$propertiesStub'
          '$endBracket',
    ];
  }
}

class ListIndexNodeFormatter extends NodeFormatter {
  const ListIndexNodeFormatter({
    this.prefix = '[',
    this.suffix = ']',
  });

  final String prefix;
  final String suffix;

  @override
  List<String> format(covariant ListIndexNode node, DumpConfig config) {
    return [
      '$prefix'
          '${node.index}'
          '$suffix',
    ];
  }
}

class LinesNodeFormatter extends NodeFormatter {
  const LinesNodeFormatter();

  @override
  List<String> format(covariant LinesNode node, DumpConfig config) {
    return node.lines;
  }
}

class DumpConfig {
  const DumpConfig({
    this.nodeFormatters = const {
      NullNode: NullNodeFormatter(),
      ValueNode: ValueNodeFormatter(),
      StringNode: StringNodeFormatter(),
      EnumNode: EnumNodeFormatter(),
      ClassNode: GroupNodeFormatter(startBracket: '(', endBracket: ')'),
      PairNode: PairNodeFormatter(),
      RecursionNode: RecursionNodeFormatter(),
      ListNode: GroupNodeFormatter(startBracket: '[', endBracket: ']'),
      ListIndexNode: ListIndexNodeFormatter(),
      LinesNode: LinesNodeFormatter(),
      MapNode: GroupNodeFormatter(startBracket: '{', endBracket: '}'),
    },
    this.toNode = objectToNode,
    this.spacer = '  ',
    this.level = 0,
  });

  final Node Function(Object? object) toNode;
  final Map<Type, NodeFormatter> nodeFormatters;
  final String spacer;
  final int level;

  DumpConfig copyWith({
    Map<Type, NodeFormatter>? nodeFormatters,
    String? spacer,
    int? level,
  }) {
    return DumpConfig(
      nodeFormatters: nodeFormatters ?? this.nodeFormatters,
      spacer: spacer ?? this.spacer,
      level: level ?? this.level,
    );
  }

  List<String> format(Node node, DumpConfig config) {
    return _formatterFor(node).format(node, this);
  }

  NodeFormatter _formatterFor(Node node) {
    final formatter = nodeFormatters[node.runtimeType];
    if (formatter == null) {
      throw Exception(
        'The node formatter is not found for the node of type ${node.runtimeType}',
      );
    }
    return formatter;
  }
}

Iterable<String> dumpStrings(
  Object? object, {
  DumpConfig config = const DumpConfig(),
}) sync* {
  final node = object is Node ? object : config.toNode(object);
  final formatter = config.nodeFormatters[node.runtimeType];
  if (formatter != null) {
    for (final line in formatter.format(node, config)) {
      yield line;
    }
  } else {
    yield '<unhandled node: $node>';
  }
}

String dump(
  Object? object, {
  String newLine = '\n',
  DumpConfig config = const DumpConfig(),
}) {
  return dumpStrings(object, config: config).toList().join(newLine);
}
