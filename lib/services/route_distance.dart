import 'package:latlong2/latlong.dart' as latlong;

// Two parts of the route closer than this (in meters) count as
// "the same spot on the road", like the outbound and return trip on one street.
const double _sameSpotMeters = 25.0;

double calculateDistanceAlongRoute(
  latlong.LatLng pickup,
  latlong.LatLng destination,
  List<latlong.LatLng> routePoints,
) {
  // roundResult: false keeps exact distances instead of rounding to whole meters
  final distanceCalculator = latlong.Distance(roundResult: false);

  // cumulative[i] = how far point i is from the start, measured along the route
  final List<double> cumulative = [0];
  for (int i = 1; i < routePoints.length; i++) {
    cumulative.add(
      cumulative[i - 1] + distanceCalculator(routePoints[i - 1], routePoints[i]),
    );
  }

  // Full loop length: the whole route, plus the gap from the last point back to the first
  final double totalLength =
      cumulative.last + distanceCalculator(routePoints.last, routePoints.first);

  final pickupSpots = _spotsNear(pickup, routePoints, distanceCalculator);
  final destinationSpots = _spotsNear(destination, routePoints, distanceCalculator);

  // Try every pass combination and keep the shortest forward ride
  double shortest = double.infinity;
  for (final p in pickupSpots) {
    for (final d in destinationSpots) {
      final double forward = d >= p
          ? cumulative[d] - cumulative[p]
          : totalLength - cumulative[p] + cumulative[d]; // wraps around the loop
      if (forward < shortest) {
        shortest = forward;
      }
    }
  }

  return shortest; // in meters
}

// Returns the position of every route point that is the same spot on the road as [target]
List<int> _spotsNear(
  latlong.LatLng target,
  List<latlong.LatLng> routePoints,
  latlong.Distance distanceCalculator,
) {
  double nearest = double.infinity;
  for (final point in routePoints) {
    final distance = distanceCalculator(target, point);
    if (distance < nearest) {
      nearest = distance;
    }
  }

  final List<int> spots = [];
  for (int i = 0; i < routePoints.length; i++) {
    if (distanceCalculator(target, routePoints[i]) <= nearest + _sameSpotMeters) {
      spots.add(i);
    }
  }
  return spots;
}