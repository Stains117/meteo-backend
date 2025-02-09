import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    "Torino": LatLng(45.0703, 7.6869),
    "Firenze": LatLng(43.7696, 11.2558),
    "Parigi": LatLng(48.8566, 2.3522),
    "Berlino": LatLng(52.5200, 13.4050),
    "Londra": LatLng(51.5074, -0.1278),
    "Madrid": LatLng(40.4168, -3.7038),
    "Amsterdam": LatLng(52.3676, 4.9041),
    "Vienna": LatLng(48.2082, 16.3738),
  };

  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  Future<void> getCurrentLocation() async {
    setState(() => isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        weatherData = {"error": "Errore GPS: ${e.toString()}"};
        isLoading = false;
      });
    }
  }

  Future<void> fetchWeather(double lat, double lon) async {
    final url = Uri.parse("https://meteo-backend.onrender.com/weather?lat=$lat&lon=$lon");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          weatherData = {"error": "Errore nel caricamento"};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        weatherData = {"error": "Errore di connessione"};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("Meteo App")),
        body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: LatLng(48.8566, 2.3522), // Parigi come centro iniziale
                zoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: cities.entries.map((entry) {
                    return Marker(
                      point: entry.value,
                      width: 40,
                      height: 40,
                      builder: (ctx) => GestureDetector(
                        onTap: () {
                          fetchWeather(entry.value.latitude, entry.value.longitude);
                        },
                        child: Icon(Icons.location_on, color: Colors.red, size: 30),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            Positioned(
              bottom: 30,
              left: 20,
              child: ElevatedButton(
                onPressed: getCurrentLocation,
                child: Text("Usa la mia posizione"),
              ),
            ),
            if (weatherData != null)
              Positioned(
                bottom: 100,
                left: 20,
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weatherData!.containsKey("error")
                        ? [Text(weatherData!["error"], style: TextStyle(color: Colors.red))]
                        : [
                            Text("Temperatura: ${weatherData!["temperature"]}°C",
                                style: TextStyle(fontSize: 20)),
                            Text("Umidità: ${weatherData!["humidity"]}%",
                                style: TextStyle(fontSize: 18)),
                            Text("Vento: ${weatherData!["wind_speed"]} m/s",
                                style: TextStyle(fontSize: 18)),
                          ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
