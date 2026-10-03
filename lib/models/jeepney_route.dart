class LatLng {
  final double lat;
  final double lng;

  LatLng({required this.lat, required this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      lat: json['lat'],
      lng: json['lng'],
    );
  }
}

class JeepneyRoute {
  final String id;
  final String name;
  final String start;
  final String end;
  final List<LatLng> coordinates;

  JeepneyRoute({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.coordinates,
  });

  factory JeepneyRoute.fromJson(Map<String, dynamic> json) {
    var coordsList = json['coordinates'] as List;
    List<LatLng> coords =
        coordsList.map((c) => LatLng.fromJson(c)).toList();

    return JeepneyRoute(
      id: json['id'],
      name: json['name'],
      start: json['start'],
      end: json['end'],
      coordinates: coords,
    );
  }
}