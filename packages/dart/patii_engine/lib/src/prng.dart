/// Deterministic Seeded PRNG (Mulberry32) matching packages/game-engine/src/core/prng.ts
class SeedRng {
  int _state;

  SeedRng(String seed) : _state = _hashSeed(seed);

  static int _hashSeed(String seed) {
    int h = 0x811c9dc5;
    for (int i = 0; i < seed.length; i++) {
      h = (h ^ seed.codeUnitAt(i)) & 0xFFFFFFFF;
      h = _imul(h, 0x01000193);
    }
    return h & 0xFFFFFFFF;
  }

  static int _imul(int a, int b) {
    final aLo = a & 0xFFFF;
    final aHi = (a >> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final bHi = (b >> 16) & 0xFFFF;
    final c = (aLo * bLo) & 0xFFFFFFFF;
    final d = (((aHi * bLo) & 0xFFFF) + ((aLo * bHi) & 0xFFFF)) & 0xFFFF;
    return (c + (d << 16)) & 0xFFFFFFFF;
  }

  double next() {
    _state = (_state + 0x6d2b79f5) & 0xFFFFFFFF;
    int z = _state;
    z = _imul(z ^ (z >> 15), z | 1);
    z = (z ^ (z + _imul(z ^ (z >> 7), z | 61))) & 0xFFFFFFFF;
    final res = ((z ^ (z >> 14)) & 0xFFFFFFFF);
    return res / 4294967296.0;
  }

  int nextInt(int min, int max) {
    if (min > max) {
      throw ArgumentError('min ($min) must be <= max ($max)');
    }
    final range = max - min + 1;
    return min + (next() * range).floor();
  }

  List<T> shuffle<T>(List<T> array) {
    final copy = List<T>.from(array);
    for (int i = copy.length - 1; i > 0; i--) {
      final j = nextInt(0, i);
      final temp = copy[i];
      copy[i] = copy[j];
      copy[j] = temp;
    }
    return copy;
  }
}

List<T> seededShuffle<T>(List<T> items, String seed) {
  final rng = SeedRng(seed);
  return rng.shuffle(items);
}
