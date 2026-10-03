import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jeepney_route.dart';

Future<List<JeepneyRoute>> loadRoutes() async {
  final supabase = Supabase.instance.client;

  final response = await supabase.from('routes').select();

  return response.map((row) {
    return JeepneyRoute(
      id: row['id'].toString(),
      name: row['name'],
      start: row['start_point'],
      end: row['end_point'],
      coordinates: (row['coordinates'] as List)
          .map((coord) => LatLng.fromJson(coord))
          .toList(),
    );
  }).toList();
}