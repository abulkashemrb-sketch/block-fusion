import 'package:flutter/material.dart';

import '../models/block_color.dart';

const Map<BlockColor, Color> _blockColorPalette = {
  BlockColor.red: Color(0xFFFF5C5C),
  BlockColor.orange: Color(0xFFFF9F43),
  BlockColor.yellow: Color(0xFFFFD93D),
  BlockColor.green: Color(0xFF3DDC97),
  BlockColor.teal: Color(0xFF00D2A0),
  BlockColor.blue: Color(0xFF4D96FF),
  BlockColor.purple: Color(0xFF9B6CFF),
};

Color blockColorToColor(BlockColor color) => _blockColorPalette[color]!;
