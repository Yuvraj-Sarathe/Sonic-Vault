class AudioConstants {
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;
  static const double defaultSpeed = 1.0;
  static const double speedStep = 0.05;

  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
  static const double defaultVolume = 0.8;

  static const int defaultCrossfadeSeconds = 3;
  static const int seekStepSeconds = 5;
  static const int fastSeekStepSeconds = 10;

  // Supported sample rates
  static const List<int> supportedSampleRates = [
    8000, 11025, 16000, 22050, 44100, 48000, 96000, 192000,
  ];

  // EQ bands frequency mapping (10 bands)
  static const List<double> eqFrequencies = [
    31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
  ];

  static const double eqMinGain = -12.0;
  static const double eqMaxGain = 12.0;
  static const double eqStep = 0.5;
  static const int eqBandCount = 10;

  static const Map<String, List<double>> eqPresets = {
    'Flat': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Boost': [6, 6, 4, 2, 0, 0, 0, 0, 0, 0],
    'Vocal': [-1, -1, 0, 1, 3, 4, 3, 2, 1, 0],
    'Rock': [4, 3, 1, 0, 0, 0, 1, 3, 4, 4],
    'Jazz': [3, 2, 1, 1, 0, 0, 1, 2, 3, 3],
    'Classical': [4, 3, 2, 1, 0, 0, 1, 2, 3, 4],
    'Pop': [-1, -1, 0, 2, 4, 4, 3, 1, -1, -1],
  };
}
