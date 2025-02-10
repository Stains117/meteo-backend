import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MeteoApp());
}

class MeteoApp extends StatefulWidget {
  @override
  _MeteoAppState createState() => _MeteoAppState();
}

class _MeteoAppState extends State<MeteoApp> {
  Map<String, LatLng> cities = {
    "Roma": LatLng(41.9028, 12.4964),
    "Milano": LatLng(45.4642, 9.1900),
    "Napoli": LatLng(40.8522, 14.2681),
    "Parigi": LatLng(48.8566, 2.3522),
    "Berlino": LatLng(52.5200, 13.4050),
    "Londra": LatLng(51.5074, -0.1278),
    "Madrid": LatLng(40.4168, -3.7038),
    "Amsterdam": LatLng(52.3676, 4.9041),
    "Vienna": LatLng(48.2082, 16.3738),
  };

  LatLng? userLocation;
  bool isLoading = false;
  Map<String, dynamic>? weatherData;

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => weatherData = {"error": "GPS non attivo"});
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => weatherData = {"error": "Permesso negato"});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => weatherData = {"error": "Permessi GPS negati permanentemente"});
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() => userLocation = LatLng(position.latitude, position.longitude));

    fetchWeather(position.latitude, position.longitude);
  }

  Future<void> fetchWeather(double lat, double lon) async {
    setState(() => isLoading = true);

    final url = Uri.parse("https://meteo-backend.onrender.com/weather?lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => weatherData = json.decode(response.body));
      } else {
        setState(() => weatherData = {"error": "Errore nel caricamento"});
      }
    } catch (e) {
      setState(() => weatherData = {"error": "Errore di connessione"});
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("Meteo App")),
        body: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(48.8566, 2.3522), // Centro sulla Francia
                  zoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      // Pin città principali
                      for (var city in cities.entries)
                        Marker(
                          point: city.value,
                          width: 40,
                          height: 40,
                          builder: (context) => IconButton(
                            icon: Icon(Icons.location_on, color: Colors.red),
                            onPressed: () => fetchWeather(city.value.latitude, city.value.longitude),
                          ),
                        ),
                      // Pin posizione utente
                      if (userLocation != null)
                        Marker(
                          point: userLocation!,
                          width: 40,
                          height: 40,
                          builder: (context) => Icon(Icons.person_pin_circle, color: Colors.blue, size: 30),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: isLoading
                  ? CircularProgressIndicator()
                  : weatherData == null
                      ? Text("Seleziona una città sulla mappa", style: TextStyle(fontSize: 18))
                      : weatherData!.containsKey("error")
                          ? Text(weatherData!["error"], style: TextStyle(fontSize: 18, color: Colors.red))
                          : Column(
                              children: [
                                Text("Temperatura: ${weatherData!['temperature']}°C", style: TextStyle(fontSize: 22)),
                                Text("Umidità: ${weatherData!['humidity']}%", style: TextStyle(fontSize: 18)),
                                Text("Vento: ${weatherData!['wind_speed']} m/s", style: TextStyle(fontSize: 18)),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: getCurrentLocation,
                                  child: Text("Usa la mia posizione"),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
