import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MeteoApp());
}

class MeteoApp extends StatefulWidget {
  @override
  _MeteoAppState createState() => _MeteoAppState();
}

class _MeteoAppState extends State<MeteoApp> {
  String city = "Roma"; // Default
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  Future<void> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          weatherData = {"error": "Permessi negati permanentemente. Attivali dalle impostazioni."};
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      openAppSettings(); // Apre le impostazioni per attivare i permessi manualmente
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Controlla se il GPS è abilitato
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          weatherData = {"error": "GPS non attivo. Attivalo e riprova."};
          isLoading = false;
        });
        return;
      }

      // Controlla i permessi
      await checkLocationPermission();

      // Ottiene la posizione attuale
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
  void initState() {
    super.initState();
    getCurrentLocation(); // Ottieni la posizione all’avvio
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("Meteo App")),
        body: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : weatherData == null
                  ? Text("Nessun dato ricevuto", style: TextStyle(fontSize: 20))
                  : weatherData!.containsKey("error")
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(weatherData!["error"],
                                style: TextStyle(fontSize: 20, color: Colors.red)),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: checkLocationPermission,
                              child: Text("Concedi permessi GPS"),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Temperatura: ${weatherData!['temperature']}°C",
                                style: TextStyle(fontSize: 22)),
                            Text("Umidità: ${weatherData!['humidity']}%",
                                style: TextStyle(fontSize: 18)),
                            Text("Vento: ${weatherData!['wind_speed']} m/s",
                                style: TextStyle(fontSize: 18)),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: getCurrentLocation,
                              child: Text("Aggiorna posizione"),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
