/// Bayer 4x4 ordered dithering matrix and threshold computation.
class BayerDither {
  BayerDither._();

  /// Bayer 4x4 threshold matrix (values 0-15, normalized to 0.0-1.0).
  static const List<List<double>> matrix4x4 = [
    [0 / 16, 8 / 16, 2 / 16, 10 / 16],
    [12 / 16, 4 / 16, 14 / 16, 6 / 16],
    [3 / 16, 11 / 16, 1 / 16, 9 / 16],
    [15 / 16, 7 / 16, 13 / 16, 5 / 16],
  ];

  /// Returns the threshold value for pixel position (x, y).
  /// The position is wrapped to the 4x4 matrix.
  static double threshold(int x, int y) {
    return matrix4x4[y % 4][x % 4];
  }

  /// Returns true if the pixel at (x, y) should use color B instead of color A,
  /// given a mix ratio (0.0 = all A, 1.0 = all B).
  static bool shouldUseColorB(int x, int y, double mixRatio) {
    return mixRatio > threshold(x, y);
  }
}
