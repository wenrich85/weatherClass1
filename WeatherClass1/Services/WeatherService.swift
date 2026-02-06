//
//  WeatherService.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation

// MARK: - Weather Service

final class WeatherService {
    
    // MARK: - Constants
    
    private enum APIEndpoint {
        static let geocoding = "https://geocoding-api.open-meteo.com/v1/search"
        static let forecast = "https://api.open-meteo.com/v1/forecast"
    }
    
    // MARK: - Public Methods
    
    /// Fetches current weather for a city name (geocodes first, then fetches weather)
    func fetchCurrentWeather(forCity city: String) async throws -> (location: GeocodingResult, weather: CurrentWeather) {
        let geocodingResult = try await fetchCoordinates(forCity: city)
        let currentWeather = try await fetchWeather(latitude: geocodingResult.latitude, longitude: geocodingResult.longitude)
        return (geocodingResult, currentWeather)
    }
    
    /// Fetches current weather for known coordinates (used for saved locations)
    func fetchWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        guard var urlComponents = URLComponents(string: APIEndpoint.forecast) else {
            throw NetworkError.invalidUrl
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await performGetRequest(url: url)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        
        return response.current_weather
    }
    
    /// Searches for cities matching the query (returns multiple results for selection)
    func searchCities(query: String, count: Int = 5) async throws -> [GeocodingResult] {
        guard var urlComponents = URLComponents(string: APIEndpoint.geocoding) else {
            throw NetworkError.invalidUrl
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await performGetRequest(url: url)
        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        
        return response.results ?? []
    }
    
    // MARK: - Private Methods
    
    /// Fetches coordinates for a city name (returns first result)
    private func fetchCoordinates(forCity city: String) async throws -> GeocodingResult {
        let results = try await searchCities(query: city, count: 1)
        
        guard let firstResult = results.first else {
            throw NetworkError.noResults
        }
        
        return firstResult
    }
    
    /// Performs a GET request and returns the response data
    private func performGetRequest(url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatusCode(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidUrl
    case invalidResponse
    case badStatusCode(statusCode: Int)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badStatusCode(let code):
            return "Server returned error code: \(code)"
        case .noResults:
            return "No results found"
        }
    }
}
