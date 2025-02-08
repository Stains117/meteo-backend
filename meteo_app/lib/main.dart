import 'package:flutter/material.dart';
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
  String city = "Roma"; // Default
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Controlla se il GPS è abilitato
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          weatherData = {"error": "GPS non attivo"};
          isLoading = false;
        });
        return;
      }

      // Controlla i permessi
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            weatherData = {"error": "Permesso negato"};
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          weatherData = {"error": "Permessi GPS negati permanentemente"};
          isLoading = false;
        });
        return;
      }

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
    // 🔹 AGGIORNATO: Usiamo il backend Railway invece del localhost
    final url = Uri.parse("https://meteo-backend-production.up.railway.app/weather?lat=$lat&lon=$lon");

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
    getCurrentLocation(); // Ottieni la posizione all'avvio
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
                      ? Text(weatherData!["error"],
                          style: TextStyle(fontSize: 20, color: Colors.red))
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
