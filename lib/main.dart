import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/jeepney_route.dart';
import 'services/route_loader.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

import 'services/route_snapper.dart';
import 'services/route_distance.dart';
import 'services/fare_calculator.dart';
import 'screens/login_screen.dart';
import 'screens/auth_components.dart';

enum SelectionMode { pickup, destination }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yjtyxslrlmfdtgnryzzo.supabase.co',
    anonKey: 'sb_publishable_azDCX3FscoVOEmiWLrdR1g_n02Hee7q',
  );

  runApp(const SakayFareApp());
}

class SakayFareApp extends StatelessWidget {
  const SakayFareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SakayFare',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: authInk),
        scaffoldBackgroundColor: authBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: authInk,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color(0xFFD9DFD7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color(0xFFD9DFD7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: authInk, width: 1.5),
          ),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: authInk,
          textColor: authInk,
          collapsedIconColor: authInk,
          collapsedTextColor: authInk,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: authBackground,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: authInk,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<JeepneyRoute>> _routesFuture;

  latlong.LatLng? _pickupPoint;
  latlong.LatLng? _destinationPoint;
  SelectionMode _selectionMode = SelectionMode.pickup;
  JeepneyRoute? _selectedRoute;
  PassengerType _passengerType = PassengerType.regular;
  FareRuleSet _fareRuleSet = FareRuleSet.prototype;
  String _routeSearchQuery = '';
  final ExpansionTileController _routesController = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    _routesFuture = loadRoutes();
  }

  List<latlong.LatLng> _convertCoordinates(JeepneyRoute route) {
    return route.coordinates
        .map((coord) => latlong.LatLng(coord.lat, coord.lng))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_bus_filled, color: Color(0xFFE6B84B)),
            SizedBox(width: 10),
            Text('SakayFare'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Route paths from OpenStreetMap data — not official LTFRB data',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ROUTES SECTION
          ExpansionTile(
            controller: _routesController,
            leading: const Icon(Icons.alt_route_rounded),
            title: Text(
              _selectedRoute == null ? 'Routes' : _selectedRoute!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search route...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _routeSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: FutureBuilder<List<JeepneyRoute>>(
                  future: _routesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error loading routes: ${snapshot.error}'),
                      );
                    }

                    final routes = snapshot.data!.where((route) {
                      final text = '${route.name} ${route.start} ${route.end}'
                          .toLowerCase();
                      return text.contains(_routeSearchQuery);
                    }).toList();

                    if (routes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No routes found'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return ListTile(
                          title: Text(route.name),
                          subtitle: Text('${route.start} → ${route.end}'),
                          selected: _selectedRoute?.id == route.id,
                          onTap: () {
                            setState(() {
                              _selectedRoute = route;
                              _pickupPoint = null;
                              _destinationPoint = null;
                            });
                            _routesController.collapse();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // DIRECTIONS SECTION
          ExpansionTile(
            leading: const Icon(Icons.pin_drop_outlined),
            title: const Text('Directions'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _pickupPoint = null;
                      _destinationPoint = null;
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset points'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<SelectionMode>(
                    segments: const [
                      ButtonSegment(
                        value: SelectionMode.pickup,
                        icon: Icon(Icons.trip_origin_rounded),
                        label: Text('Pickup'),
                      ),
                      ButtonSegment(
                        value: SelectionMode.destination,
                        icon: Icon(Icons.location_on_outlined),
                        label: Text('Destination'),
                      ),
                    ],
                    selected: {_selectionMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() => _selectionMode = selection.first);
                    },
                  ),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(
                  Icons.trip_origin_rounded,
                  color: Color(0xFFD96B53),
                ),
                title: Text(
                  _pickupPoint == null
                      ? 'Pickup: not set'
                      : 'Pickup: ${_pickupPoint!.latitude.toStringAsFixed(4)}, ${_pickupPoint!.longitude.toStringAsFixed(4)}',
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFB47D18),
                ),
                title: Text(
                  _destinationPoint == null
                      ? 'Destination: not set'
                      : 'Destination: ${_destinationPoint!.latitude.toStringAsFixed(4)}, ${_destinationPoint!.longitude.toStringAsFixed(4)}',
                ),
              ),
            ],
          ),

          // MAP
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: latlong.LatLng(7.0731, 125.6128), // Davao City
                initialZoom: 13,
                onTap: (tapPosition, point) {
                  if (_selectedRoute == null) return;

                  final routeCoords = _convertCoordinates(_selectedRoute!);
                  final snapped = snapToRoute(point, routeCoords);

                  setState(() {
                    if (_selectionMode == SelectionMode.pickup) {
                      _pickupPoint = snapped;
                    } else {
                      _destinationPoint = snapped;
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sakayfare',
                ),
                if (_selectedRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _convertCoordinates(_selectedRoute!),
                        strokeWidth: 4,
                        color: authInk,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_pickupPoint != null)
                      Marker(
                        point: _pickupPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFD96B53),
                          size: 40,
                        ),
                      ),
                    if (_destinationPoint != null)
                      Marker(
                        point: _destinationPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFB47D18),
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // DISTANCE + FARE DISPLAY
          if (_pickupPoint != null &&
              _destinationPoint != null &&
              _selectedRoute != null)
            Builder(
              builder: (context) {
                final distanceMeters = calculateDistanceAlongRoute(
                  _pickupPoint!,
                  _destinationPoint!,
                  _convertCoordinates(_selectedRoute!),
                );
                final distanceKm = distanceMeters / 1000;
                final fare = FareCalculator.calculateFare(
                  distanceKm,
                  _passengerType,
                  _fareRuleSet,
                );

                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD9DFD7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            color: authInk,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${distanceKm.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                color: authInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Text(
                            'ESTIMATED FARE',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₱${fare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: authInk,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      DropdownButton<PassengerType>(
                        isExpanded: true,
                        value: _passengerType,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _passengerType = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: PassengerType.regular,
                            child: Text('Regular passenger'),
                          ),
                          DropdownMenuItem(
                            value: PassengerType.discounted,
                            child: Text('Student / Senior / PWD (20% off)'),
                          ),
                        ],
                      ),
                      DropdownButton<FareRuleSet>(
                        isExpanded: true,
                        value: _fareRuleSet,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _fareRuleSet = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: FareRuleSet.prototype,
                            child: Text('Prototype rate (demo)'),
                          ),
                          DropdownMenuItem(
                            value: FareRuleSet.official2026,
                            child: Text('LTFRB rate (effective Sept 28, 2026)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
