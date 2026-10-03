import 'package:latlong2/latlong.dart' as latlong;

latlong.LatLng snapToRoute(latlong.LatLng tappedPoint, List<latlong.LatLng> routePoints) {
  final distanceCalculator = latlong.Distance();

  latlong.LatLng closestPoint = routePoints.first;
  double closestDistance = distanceCalculator(tappedPoint, routePoints.first);

  for (final point in routePoints) {
    final distance = distanceCalculator(tappedPoint, point);
    if (distance < closestDistance) {
      closestDistance = distance;
      closestPoint = point;
    }
  }

  return closestPoint;
}