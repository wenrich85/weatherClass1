//
//  WeatherViewModel.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    
    @Published var searchText: String = ""
    @Published var cityName: String = ""
    @Published var temperature: String = ""
    @Published var windText: String = ""
    @Published var timeText: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let weatherNetworkService: WeatherService = WeatherService()
    
    func searchWeather() async {
        
        self.errorMessage = ""
        self.isLoading = true
        
        let trimmedText: String  = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            self.errorMessage = "Please enter a city name."
            self.isLoading = false
            
        }
        
        do{
            let result = try await weatherNetworkService.fetchCurrentWeather(forCity: trimmedText)
            self.cityName = result.cityName
            self.temperature = "\(result.weather.temperature)°C"
            self.windText = "Wind: \(result.weather.windspeed) km/h"
            self.timeText = "Last updated: \(result.weather.time)"
            
            self.isLoading = false
            
            
        } catch {
            self.errorMessage = "Failed to fetch weather."
            self.isLoading = false
        }
        
    }
    
    
}
