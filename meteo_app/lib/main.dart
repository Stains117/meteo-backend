import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MeteoApp());
}

class MeteoApp extends StatefulWidget {
  @override
  _MeteoAppState createState() => _MeteoAppState();
}

class _MeteoAppState extends State<MeteoApp> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  LatLng? selectedLocation;

  final Map<String, LatLng> cities = {
    "Roma": LatLng(41.9028, 12.4964),
    "Milano": LatLng(45.4642, 9.1900),
    "Parigi": LatLng(48.8566, 2.3522),
    "Berlino": LatLng(52.5200, 13.4050),
    "Londra": LatLng(51.5074, -0.1278),
    "Madrid": LatLng(40.4168, -3.7038),
  };

  Future<void> getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      fetchWeather(position.latitude, position.longitude);
      setState(() => selectedLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() => weatherData = {"error": "Errore GPS: ${e.toString()}"});
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchWeather(double lat, double lon) async {
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
    }
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
                  center: LatLng(48.8566, 2.3522),
                  zoom: 5.0,
                  onTap: (tapPosition, latLng) {
                    setState(() => selectedLocation = latLng);
                    fetchWeather(latLng.latitude, latLng.longitude);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: cities.entries.map((entry) => Marker(
                      width: 40.0,
                      height: 40.0,
                      point: entry.value,
                      builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 30),
                    )).toList(),
                  )
                ],
              ),
            ),
            if (weatherData != null)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: weatherData!.containsKey("error")
                    ? Text(weatherData!["error"],
                        style: TextStyle(fontSize: 18, color: Colors.red))
                    : Column(
                        children: [
                          Text("Temperatura: ${weatherData!["temperature"]}°C",
                              style: TextStyle(fontSize: 22)),
                          Text("Umidità: ${weatherData!["humidity"]}%",
                              style: TextStyle(fontSize: 18)),
                          Text("Vento: ${weatherData!["wind_speed"]} m/s",
                              style: TextStyle(fontSize: 18)),
                        ],
                      ),
              ),
            ElevatedButton(
              onPressed: getCurrentLocation,
              child: Text("Usa la mia posizione"),
            ),
          ],
        ),
      ),
    );
  }
}
