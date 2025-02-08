from flask import Flask, jsonify, request
import openmeteo_requests
import requests_cache
import pandas as pd
from retry_requests import retry

app = Flask(__name__)

# Configura Open-Meteo con cache e gestione errori
cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
openmeteo = openmeteo_requests.Client(session=retry_session)

# Dizionario con coordinate di alcune città europee
city_coordinates = {
    "roma": (41.9028, 12.4964),
    "milano": (45.4642, 9.1900),
    "napoli": (40.8522, 14.2681),
    "torino": (45.0703, 7.6869),
    "firenze": (43.7696, 11.2558),
    "parigi": (48.8566, 2.3522),
    "berlino": (52.5200, 13.4050),
    "londra": (51.5074, -0.1278),
    "madrid": (40.4168, -3.7038),
    "amsterdam": (52.3676, 4.9041),
    "vienna": (48.2082, 16.3738)
}

@app.route('/')
def home():
    return jsonify({"message": "Benvenuto nel server Meteo API! Usa /weather con city o lat/lon per ottenere i dati."})

@app.route('/weather', methods=['GET'])
def get_weather():
    lat = request.args.get('lat')
    lon = request.args.get('lon')
    city = request.args.get('city')

    # Se l'utente fornisce il nome della città, la converte in coordinate
    if city and not lat and not lon:
        city = city.lower()
        if city in city_coordinates:
            lat, lon = city_coordinates[city]
        else:
            return jsonify({"error": "Città non supportata"}), 400

    # Se non ci sono né lat/lon né città valide, restituisci errore
    if not lat or not lon:
        return jsonify({"error": "Devi fornire latitudine/longitudine o il nome di una città"}), 400

    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": ["temperature_2m", "relative_humidity_2m", "wind_speed_10m"],
        "timezone": "Europe/Rome"
    }

    try:
        responses = openmeteo.weather_api(url, params=params)

        if not responses:
            return jsonify({"error": "Errore nel recupero dei dati"}), 500

        response = responses[0]
        current = response.Current()

        return jsonify({
            "city": city.capitalize() if city else "Coordinate personalizzate",
            "temperature": current.Variables(0).Value(),
            "humidity": current.Variables(1).Value(),
            "wind_speed": current.Variables(2).Value()
        })

    except Exception as e:
        return jsonify({"error": f"Errore durante la richiesta: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

