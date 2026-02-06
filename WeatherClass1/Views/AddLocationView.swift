//
//  AddLocationView.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import SwiftUI

struct AddLocationView: View {
    
    // MARK: - Environment & Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: WeatherViewModel
    let existingCount: Int
    
    // MARK: - State
    
    @State private var selectedResult: GeocodingResult?
    @State private var showingConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Content
                if viewModel.isSearching {
                    loadingView
                } else if !viewModel.searchResults.isEmpty {
                    searchResultsList
                } else if !viewModel.searchText.isEmpty {
                    noResultsView
                } else {
                    instructionsView
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                Button("OK") {
                    viewModel.errorMessage = ""
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingConfirmation) {
                if let result = selectedResult {
                    confirmationSheet(for: result)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search for a city...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .onSubmit {
                    Task {
                        await viewModel.searchCities()
                    }
                }
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.bar)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        List(viewModel.searchResults) { result in
            Button {
                selectedResult = result
                showingConfirmation = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(result.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
    
    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            Text("No cities found matching '\(viewModel.searchText)'")
        }
    }
    
    private var instructionsView: some View {
        ContentUnavailableView {
            Label("Search for a City", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Enter a city name to search.\nYou can add up to \(WeatherViewModel.maxLocations - existingCount) more location\(WeatherViewModel.maxLocations - existingCount == 1 ? "" : "s").")
        }
    }
    
    // MARK: - Confirmation Sheet
    
    private func confirmationSheet(for result: GeocodingResult) -> some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.name)
                            .font(.title2)
                            .bold()
                        Text(result.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Optional Note") {
                    TextField("e.g., Home, Office, Vacation spot...", text: $viewModel.newLocationNote)
                }
                
                Section("Baseline Temperature (Optional)") {
                    HStack {
                        TextField("e.g., 20.0", text: $viewModel.newLocationBaseline)
                            .keyboardType(.decimalPad)
                        Text("°C")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Set a baseline to compare against current temperature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingConfirmation = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addLocation(from: result, context: modelContext, existingCount: existingCount)
                        showingConfirmation = false
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
