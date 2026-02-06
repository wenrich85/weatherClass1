//
//  WeatherModel.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation

// MARK: - Geocoding Models (City -> Latitude/Longitude)

struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable, Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String? // State/Province
    
    var id: String { "\(latitude),\(longitude)" }
    
    /// Formatted display name (e.g., "San Francisco, California, United States")
    var displayName: String {
        var parts: [String] = [name]
        if let state = admin1 { parts.append(state) }
        if let country = country { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Weather Models (Coordinates -> Current Weather)

struct ForecastResponse: Codable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
    let time: String
    let interval: Int
    let winddirection: Int
    let is_day: Int
    
    /// Human-readable weather description based on WMO weather codes
    var weatherDescription: String {
        switch weathercode {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }
    
    /// SF Symbol name for weather condition
    var symbolName: String {
        switch weathercode {
        case 0: return is_day == 1 ? "sun.max.fill" : "moon.fill"
        case 1, 2, 3: return is_day == 1 ? "cloud.sun.fill" : "cloud.moon.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
}
