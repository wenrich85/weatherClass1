//
//  WeatherModel.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//
import Foundation

//MARK: Geocoding (City -> Latitude/Longitude)

struct GeocodingResponse: Codable {
    let results:[GeoCodingResult]?
}

struct GeoCodingResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
}

//MARK: Weather -> (Latitude/Longitude) -> Current Weather

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
}
