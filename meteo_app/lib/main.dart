import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MeteoApp());
}

class MeteoApp extends StatefulWidget {
  @override
  _MeteoAppState createState() => _MeteoAppState();
}

class _MeteoAppState extends State<MeteoApp> {
  String city = "Roma"; // Città di default
  Map<String, dynamic>? weatherData;
  bool isLoading = true; // Stato di caricamento

  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true; // Mostra il caricamento durante la richiesta
    });

    try {
      final url = Uri.parse("http://10.0.2.2:5000/weather?city=$city"); // Se usi un emulatore Android
      // Se sei su dispositivo reale, usa l'IP locale del tuo PC es. "http://192.168.1.100:5000/weather?city=$city"

      final response = await http.get(url);

      print("Risposta dal server: ${response.body}"); // Debug nel terminale

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        setState(() {
          weatherData = {"error": "Errore nel caricamento dei dati"};
        });
      }
    } catch (e) {
      setState(() {
        weatherData = {"error": "Errore di connessione: ${e.toString()}"};
      });
    } finally {
      setState(() {
        isLoading = false; // Nasconde il caricamento dopo la richiesta
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("Meteo App")),
        body: Center(
          child: isLoading
              ? CircularProgressIndicator() // Mostra il caricamento
              : weatherData == null
                  ? Text("Nessun dato ricevuto", style: TextStyle(fontSize: 20))
                  : weatherData!.containsKey("error")
                      ? Text(weatherData!["error"], style: TextStyle(fontSize: 20, color: Colors.red))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Città: ${weatherData!['city']}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text("Temperatura: ${weatherData!['temperature']}°C", style: TextStyle(fontSize: 22)),
                            Text("Umidità: ${weatherData!['humidity']}%", style: TextStyle(fontSize: 18)),
                            Text("Vento: ${weatherData!['wind_speed']} m/s", style: TextStyle(fontSize: 18)),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: fetchWeather,
                              child: Text("Aggiorna"),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}
