import 'dart:math' show max;

import 'ansi_colors.dart';
import 'dump.dart';

typedef DiffStringFormatter = String Function(String string);

String defaultAddedFormatter(String string) {
  final color = AnsiColor()..fg256(43);
  return color(string);
}

String defaultRemovedFormatter(String string) {
  final color = AnsiColor()..fg256(9);
  return color(string);
}

String defaultSameFormatter(String string) {
  final color = AnsiColor()..fg256(250);
  return color(string);
}

class DiffFormat {
  const DiffFormat({
    this.added = '+',
    this.removed = '-',
    this.same = ' ',
    this.formattingAllowed = true,
    this.addedFormat = defaultAddedFormatter,
    this.removedFormat = defaultRemovedFormatter,
    this.sameFormat = defaultSameFormatter,
  });

  final String removed;
  final String added;
  final String same;
  final bool formattingAllowed;
  final DiffStringFormatter? addedFormat;
  final DiffStringFormatter? removedFormat;
  final DiffStringFormatter? sameFormat;

  DiffFormat copyWith({
    String? removed,
    String? added,
    String? same,
    bool? formattingAllowed,
    DiffStringFormatter? addedFormat,
    DiffStringFormatter? removedFormat,
    DiffStringFormatter? sameFormat,
  }) {
    return DiffFormat(
      removed: removed ?? this.removed,
      added: added ?? this.added,
      same: same ?? this.same,
      formattingAllowed: formattingAllowed ?? this.formattingAllowed,
      addedFormat: addedFormat ?? this.addedFormat,
      removedFormat: removedFormat ?? this.removedFormat,
      sameFormat: sameFormat ?? this.sameFormat,
    );
  }

  String sameLine(String string) {
    final sameLine = '$same $string';
    return formattingAllowed && sameFormat != null ? sameFormat!(sameLine) : sameLine;
  }

  String addedLine(String string) {
    final addedLine = '$added $string';
    return formattingAllowed && addedFormat != null ? addedFormat!(addedLine) : addedLine;
  }

  String removedLine(String string) {
    final removedLine = '$removed $string';
    return formattingAllowed && removedFormat != null ? removedFormat!(removedLine) : removedLine;
  }
}

class DiffConfig {
  const DiffConfig({
    this.format = const DiffFormat(),
    this.nodeDiffFormatters = const {
      Node: DefaultNodeDiffFormatter(),
      ListNode: GroupNodeDiffFormatter(startBracket: '[', endBracket: ']'),
      MapNode: GroupNodeDiffFormatter(startBracket: '{', endBracket: '}'),
      ClassNode: GroupNodeDiffFormatter(startBracket: '(', endBracket: ')'),
      PairNode: PairNodeDiffFormatter(),
    },
    this.foldUnchanged = true,
    this.skipGroupFormatting = false,
  });

  final DiffFormat format;
  final Map<Type, NodeDiffFormatter> nodeDiffFormatters;
  final bool foldUnchanged;
  final bool skipGroupFormatting;

  DiffConfig copyWith({
    DiffFormat? format,
    Map<Type, NodeDiffFormatter>? nodeDiffFormatters,
    bool? foldUnchanged,
    bool? skipGroupFormatting,
  }) {
    return DiffConfig(
      format: format ?? this.format,
      nodeDiffFormatters: nodeDiffFormatters ?? this.nodeDiffFormatters,
      foldUnchanged: foldUnchanged ?? this.foldUnchanged,
      skipGroupFormatting: skipGroupFormatting ?? this.skipGroupFormatting,
    );
  }

  NodeDiffFormatter formatterFor(Node node) {
    final formatter =
        nodeDiffFormatters[node.runtimeType] ?? nodeDiffFormatters[Node];
    if (formatter == null) {
      throw Exception(
        'The node diff formatter is not found for the node of type ${node.runtimeType}',
      );
    }
    return formatter;
  }
}

enum NodeDiffResult { same, removed, added }

abstract class NodeDiffFormatter {
  const NodeDiffFormatter();

  List<String> formatDiff(
    Node lhs,
    Node rhs,
    DumpConfig dumpConfig,
    DiffConfig diffConfig,
  );

  List<String> format(
    Node node,
    NodeDiffResult diffResult,
    DumpConfig dumpConfig,
    DiffConfig diffConfig,
  ) {
    return dumpConfig.format(node, dumpConfig).map((line) {
      switch (diffResult) {
        case NodeDiffResult.same:
          return diffConfig.format.sameLine(line);

        case NodeDiffResult.removed:
          return diffConfig.format.removedLine(line);

        case NodeDiffResult.added:
          return diffConfig.format.addedLine(line);
      }
    }).toList();
  }
}

class DefaultNodeDiffFormatter extends NodeDiffFormatter {
  const DefaultNodeDiffFormatter();

  @override
  List<String> formatDiff(
    Node lhs,
    Node rhs,
    DumpConfig dumpConfig,
    DiffConfig diffConfig,
  ) {
    if (lhs == rhs) {
      return format(rhs, NodeDiffResult.same, dumpConfig, diffConfig);
    }
    return [
      ...format(lhs, NodeDiffResult.removed, dumpConfig, diffConfig),
      ...format(rhs, NodeDiffResult.added, dumpConfig, diffConfig),
    ];
  }
}

class GroupNodeDiffFormatter extends NodeDiffFormatter {
  const GroupNodeDiffFormatter({
    required this.startBracket,
    required this.endBracket,
    this.valuesSeparator = ',',
  });

  final String startBracket;
  final String endBracket;
  final String valuesSeparator;

  @override
  List<String> formatDiff(
    covariant GroupNode lhs,
    covariant GroupNode rhs,
    DumpConfig dumpConfig,
    DiffConfig diffConfig,
  ) {
    if (lhs == rhs) {
      return format(rhs, NodeDiffResult.same, dumpConfig, diffConfig);
    }

    List<String> lines = [];

    final startLine = dumpConfig
        .format(
          ValueNode('${lhs.name ?? ''}$startBracket'),
          dumpConfig,
        )
        .first;

    final endLine = dumpConfig
        .format(
          ValueNode(endBracket),
          dumpConfig,
        )
        .first;

    final lhsCount = lhs.values.length;
    final rhsCount = rhs.values.length;
    final count = max(lhsCount, rhsCount);
    final indent = dumpConfig.spacer * dumpConfig.level + dumpConfig.spacer;

    List<String> valuesLines = [];
    List<String> unchangedLines = [];

    for (var i = 0; i < count; i++) {
      final leftValue = i < lhsCount ? lhs.values[i] : null;
      final rightValue = i < rhsCount ? rhs.values[i] : null;

      final valuesDiffLines = diffStrings(
        leftValue,
        rightValue,
        dumpConfig: dumpConfig.copyWith(level: dumpConfig.level + 1),
        diffConfig: diffConfig,
        skipEqual: false,
        skipRemoved: leftValue == null,
        skipAdded: rightValue == null,
      );

      if (diffConfig.foldUnchanged) {
        if (valuesDiffLines.length == 1) {
          unchangedLines.addAll(valuesDiffLines);
        } else {
          _handleUnchanged(
            unchangedLines,
            valuesLines,
            indent,
            diffConfig.format,
            last: i == count - 1,
          );
          unchangedLines = [];
          valuesLines.addAll(valuesDiffLines);
        }
      } else {
        valuesLines.addAll(valuesDiffLines);
      }
    }

    if (diffConfig.foldUnchanged) {
      _handleUnchanged(unchangedLines, valuesLines, indent, diffConfig.format);
    }

    lines.add(
      diffConfig.skipGroupFormatting
          ? startLine
          : diffConfig.format.sameLine(startLine),
    );
    lines.addAll(valuesLines);
    lines.add(
      diffConfig.skipGroupFormatting
          ? endLine
          : diffConfig.format.sameLine(endLine),
    );

    return lines;
  }

  _handleUnchanged(
    List<String> unchangedLines,
    List<String> finalLines,
    String indent,
    DiffFormat format, {
    bool last = true,
  }) {
    if (unchangedLines.isEmpty) return;
    if (unchangedLines.length == 1) {
      finalLines.addAll(unchangedLines);
    } else {
      finalLines.add(
        format.sameLine(
          '$indent'
          '… (${unchangedLines.length} unchanged)'
          '${last ? '' : valuesSeparator}',
        ),
      );
    }
  }
}

class PairNodeDiffFormatter extends NodeDiffFormatter {
  const PairNodeDiffFormatter({
    this.pairSeparator = ': ',
    this.valuesSeparator = ',',
  });

  final String pairSeparator;
  final String valuesSeparator;

  @override
  List<String> formatDiff(
    covariant PairNode lhs,
    covariant PairNode rhs,
    DumpConfig dumpConfig,
    DiffConfig diffConfig,
  ) {
    if (lhs == rhs) {
      return format(rhs, NodeDiffResult.same, dumpConfig, diffConfig);
    }

    if (lhs.key == rhs.key &&
        ((lhs.value is ListNode && rhs.value is ListNode) ||
            (lhs.value is MapNode && rhs.value is MapNode) ||
            (lhs.value is ClassNode && rhs.value is ClassNode))) {
      final keyLines = dumpStrings(
        lhs.key,
        config: dumpConfig,
      ).toList();

      final valueDiffLines = diffStrings(
        lhs.value,
        rhs.value,
        dumpConfig: dumpConfig,
        diffConfig: diffConfig.copyWith(
          skipGroupFormatting: true,
        ),
        skipEqual: false,
      );

      List<String> lines = [];

      lines.addAll(
        keyLines.sublist(0, max(0, keyLines.length - 1)),
      );

      lines.add(
        diffConfig.format.sameLine(
          '${dumpConfig.spacer * dumpConfig.level}'
          '${keyLines.last}'
          '$pairSeparator'
          '${valueDiffLines.first.trimLeft()}',
        ),
      );

      if (valueDiffLines.length > 1) {
        lines.addAll(
          valueDiffLines.sublist(1, max(0, valueDiffLines.length - 1)),
        );
      }

      lines.add(
        diffConfig.format.sameLine(
          '${dumpConfig.spacer * dumpConfig.level}'
          '${valueDiffLines.last}'
          '${rhs.last ? '' : valuesSeparator}',
        ),
      );

      return lines;
    }

    final lines = diffStrings(
      LinesNode(lines: dumpStrings(lhs, config: dumpConfig).toList()),
      LinesNode(lines: dumpStrings(rhs, config: dumpConfig).toList()),
      dumpConfig: dumpConfig,
      diffConfig: diffConfig,
      skipEqual: false,
    );

    return lines;
  }
}

String diff(
  Object? lhs,
  Object? rhs, {
  DiffConfig diffConfig = const DiffConfig(),
  DumpConfig dumpConfig = const DumpConfig(),
  bool skipEqual = true,
  bool skipRemoved = false,
  bool skipAdded = false,
  String newLine = '\n',
}) {
  return diffStrings(
    lhs,
    rhs,
    diffConfig: diffConfig,
    dumpConfig: dumpConfig,
    skipEqual: skipEqual,
    skipAdded: skipAdded,
    skipRemoved: skipRemoved,
  ).join(newLine);
}

List<String> diffStrings(
  Object? lhs,
  Object? rhs, {
  DiffConfig diffConfig = const DiffConfig(),
  DumpConfig dumpConfig = const DumpConfig(),
  bool skipEqual = true,
  bool skipRemoved = false,
  bool skipAdded = false,
}) {
  if (lhs == rhs && skipEqual) return [];

  final leftNode = lhs is Node ? lhs : dumpConfig.toNode(lhs);
  final rightNode = rhs is Node ? rhs : dumpConfig.toNode(rhs);

  if (lhs.runtimeType == rhs.runtimeType ||
      (lhs is Map && rhs is Map) ||
      (lhs is List && rhs is List)) {
    return diffConfig.formatterFor(leftNode).formatDiff(
          leftNode,
          rightNode,
          dumpConfig,
          diffConfig,
        );
  }

  return [
    if (!skipRemoved)
      ...diffConfig.formatterFor(leftNode).format(
            leftNode,
            NodeDiffResult.removed,
            dumpConfig,
            diffConfig,
          ),
    if (!skipAdded)
      ...diffConfig.formatterFor(rightNode).format(
            rightNode,
            NodeDiffResult.added,
            dumpConfig,
            diffConfig,
          ),
  ];
}
