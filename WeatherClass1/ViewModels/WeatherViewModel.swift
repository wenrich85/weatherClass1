//
//  WeatherViewModel.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {
    
    // MARK: - Constants
    
    static let maxLocations = 4
    
    // MARK: - Published Properties
    
    // Search state
    @Published var searchText: String = ""
    @Published var searchResults: [GeocodingResult] = []
    @Published var isSearching: Bool = false
    
    // Loading/Error state
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String = ""
    
    // Add location sheet state
    @Published var showingAddLocation: Bool = false
    @Published var newLocationNote: String = ""
    @Published var newLocationBaseline: String = ""
    
    // MARK: - Private Properties
    
    private let weatherService: WeatherService
    
    // MARK: - Initializer
    
    init(weatherService: WeatherService = WeatherService()) {
        self.weatherService = weatherService
    }
    
    // MARK: - Public Methods
    
    /// Searches for cities matching the query
    func searchCities() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = ""
        
        do {
            searchResults = try await weatherService.searchCities(query: query)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    /// Adds a new location from search results
    func addLocation(from result: GeocodingResult, context: ModelContext, existingCount: Int) {
        guard existingCount < Self.maxLocations else {
            errorMessage = "Maximum of \(Self.maxLocations) locations allowed"
            return
        }
        
        // Parse baseline temp if provided
        let baseline = Double(newLocationBaseline.trimmingCharacters(in: .whitespaces))
        
        // Create new saved location
        let location = SavedLocation(
            cityName: result.name,
            latitude: result.latitude,
            longitude: result.longitude,
            note: newLocationNote.isEmpty ? nil : newLocationNote,
            baselineTemp: baseline
        )
        
        context.insert(location)
        
        // Reset form
        resetAddLocationForm()
        showingAddLocation = false
        
        // Fetch weather for the new location
        Task {
            await refreshWeather(for: location)
        }
    }
    
    /// Refreshes weather for all saved locations
    func refreshAllLocations(_ locations: [SavedLocation]) async {
        isRefreshing = true
        errorMessage = ""
        
        await withTaskGroup(of: Void.self) { group in
            for location in locations {
                group.addTask {
                    await self.refreshWeather(for: location)
                }
            }
        }
        
        isRefreshing = false
    }
    
    /// Refreshes weather for a single location
    func refreshWeather(for location: SavedLocation) async {
        do {
            let weather = try await weatherService.fetchWeather(
                latitude: location.latitude,
                longitude: location.longitude
            )
            location.updateWeather(from: weather)
        } catch {
            // Individual location errors don't show global error
            print("Failed to fetch weather for \(location.cityName): \(error)")
        }
    }
    
    /// Deletes a location
    func deleteLocation(_ location: SavedLocation, context: ModelContext) {
        context.delete(location)
    }
    
    /// Updates the baseline temperature for a location
    func updateBaseline(for location: SavedLocation, newBaseline: Double?) {
        location.baselineTemp = newBaseline
    }
    
    /// Sets current temp as baseline
    func setCurrentAsBaseline(for location: SavedLocation) {
        location.setCurrentAsBaseline()
    }
    
    /// Updates the note for a location
    func updateNote(for location: SavedLocation, newNote: String?) {
        location.note = newNote?.isEmpty == true ? nil : newNote
    }
    
    /// Checks if more locations can be added
    func canAddLocation(currentCount: Int) -> Bool {
        return currentCount < Self.maxLocations
    }
    
    // MARK: - Private Methods
    
    private func resetAddLocationForm() {
        searchText = ""
        searchResults = []
        newLocationNote = ""
        newLocationBaseline = ""
    }
}
