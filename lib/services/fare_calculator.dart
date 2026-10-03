enum PassengerType { regular, discounted } // discounted = student/senior/PWD
enum FareRuleSet { prototype, official2026 }

class FareCalculator {
  // Our original placeholder rates (not claimed to be official)
  static const double _prototypeBaseFare = 13.0;
  static const double _prototypeBaseDistanceKm = 4.0;
  static const double _prototypeRatePerKm = 1.80;
  static const double _prototypeDiscountPercent = 0.20;

  // LTFRB rate for Davao, sourced from DavaoWave (effective Sept 28, 2026)
  static const double _officialBaseFareRegular = 14.0;
  static const double _officialBaseFareDiscounted = 11.20; // its own rate, not 80% of regular
  static const double _officialBaseDistanceKm = 4.0;
  static const double _officialRatePerKmRegular = 2.00;
  static const double _officialRatePerKmDiscounted = 1.00; // its own rate too

  static double calculateFare(
    double distanceKm,
    PassengerType passengerType,
    FareRuleSet ruleSet,
  ) {
    if (ruleSet == FareRuleSet.prototype) {
      final double regularFare = distanceKm <= _prototypeBaseDistanceKm
          ? _prototypeBaseFare
          : _prototypeBaseFare +
              (distanceKm - _prototypeBaseDistanceKm) * _prototypeRatePerKm;
  
      return passengerType == PassengerType.discounted
          ? regularFare * (1 - _prototypeDiscountPercent)
          : regularFare;
    }

    // Official rate: base fare and per-km rate are each set directly,
    // not derived from the regular rate with a percentage.
    final double baseFare = passengerType == PassengerType.discounted
        ? _officialBaseFareDiscounted
        : _officialBaseFareRegular;
    final double ratePerKm = passengerType == PassengerType.discounted
        ? _officialRatePerKmDiscounted
        : _officialRatePerKmRegular;

    if (distanceKm <= _officialBaseDistanceKm) {
      return baseFare;
    }
    return baseFare + (distanceKm - _officialBaseDistanceKm) * ratePerKm;
  }
}