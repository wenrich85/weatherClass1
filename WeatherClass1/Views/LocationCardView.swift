//
//  LocationCardView.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import SwiftUI

struct LocationCardView: View {
    
    // MARK: - Properties
    
    @Bindable var location: SavedLocation
    @ObservedObject var viewModel: WeatherViewModel
    
    @State private var isEditing: Bool = false
    @State private var editedNote: String = ""
    @State private var editedBaseline: String = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: City name and weather icon
            headerSection
            
            // Temperature and comparison
            if location.currentTemp != nil {
                temperatureSection
            } else {
                noDataSection
            }
            
            // Note (if present)
            if let note = location.note, !note.isEmpty {
                noteSection(note: note)
            }
            
            // Last updated
            if let lastUpdated = location.lastUpdated {
                lastUpdatedSection(date: lastUpdated)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .onTapGesture {
            prepareEdit()
            isEditing = true
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.cityName)
                    .font(.title2)
                    .bold()
                
                if let weatherCode = location.weatherCode {
                    let weather = mockWeatherDescription(code: weatherCode)
                    Text(weather)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let weatherCode = location.weatherCode {
                Image(systemName: mockWeatherSymbol(code: weatherCode))
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var temperatureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current temperature
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", location.currentTemp ?? 0))
                    .font(.system(size: 48, weight: .thin))
                Text("°C")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            // Baseline comparison (if available)
            if location.baselineTemp != nil {
                baselineComparisonView
            }
            
            // Wind speed
            if let wind = location.windSpeed {
                Label("\(String(format: "%.1f", wind)) km/h", systemImage: "wind")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var baselineComparisonView: some View {
        HStack(spacing: 16) {
            // Delta
            if let delta = location.formattedDelta {
                HStack(spacing: 4) {
                    Image(systemName: deltaIcon)
                        .foregroundStyle(deltaColor)
                    Text(delta)
                        .font(.headline)
                        .foregroundStyle(deltaColor)
                }
            }
            
            // Percentage
            if let percent = location.formattedPercentChange {
                Text("(\(percent))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Baseline label
            if let baseline = location.baselineTemp {
                Text("vs \(String(format: "%.1f", baseline))°C baseline")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(deltaColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var noDataSection: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text("Weather data unavailable")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
    
    private func noteSection(note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "note.text")
                .foregroundStyle(.secondary)
            Text(note)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
    
    private func lastUpdatedSection(date: Date) -> some View {
        Text("Updated \(date.formatted(.relative(presentation: .named)))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
    
    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("Add a note...", text: $editedNote)
                }
                
                Section("Baseline Temperature") {
                    HStack {
                        TextField("e.g., 20.0", text: $editedBaseline)
                            .keyboardType(.decimalPad)
                        Text("°C")
                            .foregroundStyle(.secondary)
                    }
                    
                    if location.currentTemp != nil {
                        Button("Use Current Temperature") {
                            editedBaseline = String(format: "%.1f", location.currentTemp ?? 0)
                        }
                    }
                }
                
                if location.baselineTemp != nil {
                    Section {
                        Button("Clear Baseline", role: .destructive) {
                            editedBaseline = ""
                        }
                    }
                }
            }
            .navigationTitle("Edit \(location.cityName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                        isEditing = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties
    
    private var deltaIcon: String {
        guard let delta = location.tempDelta else { return "equal" }
        if delta > 0 { return "arrow.up" }
        if delta < 0 { return "arrow.down" }
        return "equal"
    }
    
    private var deltaColor: Color {
        guard let delta = location.tempDelta else { return .secondary }
        if delta > 0 { return .red }
        if delta < 0 { return .blue }
        return .secondary
    }
    
    // MARK: - Methods
    
    private func prepareEdit() {
        editedNote = location.note ?? ""
        editedBaseline = location.baselineTemp.map { String(format: "%.1f", $0) } ?? ""
    }
    
    private func saveEdits() {
        viewModel.updateNote(for: location, newNote: editedNote)
        viewModel.updateBaseline(for: location, newBaseline: Double(editedBaseline))
    }
    
    // Helper functions for weather display (mirrors CurrentWeather computed properties)
    private func mockWeatherDescription(code: Int) -> String {
        switch code {
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
    
    private func mockWeatherSymbol(code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
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
