/// Distinguishes a normal colored piece from a special power-up piece.
///
/// A [bomb] clears the area it lands on; a [wildcard] places a colorless
/// cell that counts as whatever color the line around it turns out to be,
/// which is what makes a same-color line bonus reachable in practice.
enum BlockKind { normal, bomb, wildcard }
