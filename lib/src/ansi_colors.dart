import 'dart:math' show min, max;

/// ANSI colors
/// https://en.wikipedia.org/wiki/ANSI_escape_code
/// https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html
class AnsiColor {
  AnsiColor();

  String _codes = '';
  final _escape = '\x1B[';
  String get _reset => '${_escape}0m';

  String call(Object? message) => '$_codes${message.toString()}$_reset';

  bold() => _codes += '${_escape}1m';

  faint() => _codes += '${_escape}2m';

  underline() => _codes += '${_escape}4m';

  slowBlink() => _codes += '${_escape}5m';

  rapidBlink() => _codes += '${_escape}6m';

  inverted() => _codes += '${_escape}7m';

  hide() => _codes += '${_escape}8m';

  strike() => _codes += '${_escape}9m';

  doublyUnderlined() => _codes += '${_escape}21m';

  sup() => _codes += '${_escape}73m';

  sub() => _codes += '${_escape}74m';

  /// `r`, `g` and `b` are in range 0..255
  fgRGB(double r, double g, double b) => _colorRGB(r, g, b, false);

  /// `r`, `g` and `b` are in range 0..255
  bgRGB(double r, double g, double b) => _colorRGB(r, g, b, true);

  /// i in range 0..7
  fg8(int i) => _color8(i, false, false);

  /// i in range 0..7
  bg8(int i) => _color8(i, true, false);

  /// i in range 0..7
  fgBright8(int i) => _color8(i, false, true);

  /// i in range 0..7
  bgBright8(int i) => _color8(i, true, true);

  /// i in range 0..255
  fg256(int i) => _color256(i, false);

  /// i in range 0..255
  bg256(int i) => _color256(i, true);

  _colorRGB(double r, double g, double b, bool bg) {
    _codes += '$_escape${bg ? '48' : '38'};2;${r.toInt()};${g.toInt()};${b.toInt()}m';
  }

  _color8(int i, bool bg, bool bright) {
    /// Background: \x1b[${ID}m, where ID within 30...37
    /// Foreground: \x1b[${ID}m, where ID within 90...97
    final iMin = (bg ? 40 : 30) + (bright ? 60 : 0);
    final iMax = iMin + 7;
    final color = max(iMin, min(iMax, iMin + i));
    _codes += '$_escape${color}m';
  }

  /// Foreground:
  ///   \x1b[38;5;${ID}m, where ID within 0...255
  ///   https://www.lihaoyi.com/post/Ansi/Rainbow256.png
  /// Background:
  ///   \x1b[48;5;${ID}m, where ID within 0...255
  ///   https://www.lihaoyi.com/post/Ansi/RainbowBackground256.png
  _color256(int i, bool bg) {
    _codes += '$_escape${bg ? '48' : '38'};5;${max(0, min(255, i))}m';
  }
}
