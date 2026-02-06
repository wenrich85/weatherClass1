//
//  SavedLocation.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation
import SwiftData

@Model
final class SavedLocation {
    
    // MARK: - Stored Properties
    var cityName: String
    var latitude: Double
    var longitude: Double
    var note: String?
    var baselineTemp: Double?
    var currentTemp: Double?
    var windSpeed: Double?
    var weatherCode: Int?
    var lastUpdated: Date?
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    /// Temperature difference from baseline (current - baseline)
    var tempDelta: Double? {
        guard let current = currentTemp, let baseline = baselineTemp else {
            return nil
        }
        return current - baseline
    }
    
    /// Percentage change from baseline
    var tempPercentChange: Double? {
        guard let current = currentTemp, let baseline = baselineTemp, baseline != 0 else {
            return nil
        }
        return ((current - baseline) / abs(baseline)) * 100
    }
    
    /// Formatted delta string (e.g., "+5.2°C" or "-3.1°C")
    var formattedDelta: String? {
        guard let delta = tempDelta else { return nil }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta))°C"
    }
    
    /// Formatted percentage string (e.g., "+12.5%" or "-8.3%")
    var formattedPercentChange: String? {
        guard let percent = tempPercentChange else { return nil }
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percent))%"
    }
    
    // MARK: - Initializer
    
    init(
        cityName: String,
        latitude: Double,
        longitude: Double,
        note: String? = nil,
        baselineTemp: Double? = nil
    ) {
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.note = note
        self.baselineTemp = baselineTemp
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    /// Updates weather data from API response
    func updateWeather(from weather: CurrentWeather) {
        self.currentTemp = weather.temperature
        self.windSpeed = weather.windspeed
        self.weatherCode = weather.weathercode
        self.lastUpdated = Date()
    }
    
    /// Sets the current temperature as the new baseline
    func setCurrentAsBaseline() {
        if let current = currentTemp {
            baselineTemp = current
        }
    }
}
