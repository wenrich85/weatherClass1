//
//  WeatherView.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import SwiftUI
import SwiftData

struct WeatherView: View {
    
    // MARK: - Environment & State
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLocation.createdAt) private var savedLocations: [SavedLocation]
    @StateObject private var viewModel = WeatherViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if savedLocations.isEmpty {
                    emptyStateView
                } else {
                    locationListView
                }
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .sheet(isPresented: $viewModel.showingAddLocation) {
                AddLocationView(viewModel: viewModel, existingCount: savedLocations.count)
            }
            .refreshable {
                await viewModel.refreshAllLocations(savedLocations)
            }
            .task {
                // Refresh weather on appear if we have locations
                if !savedLocations.isEmpty {
                    await viewModel.refreshAllLocations(savedLocations)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Locations", systemImage: "cloud.sun")
        } description: {
            Text("Add up to \(WeatherViewModel.maxLocations) locations to track their weather.")
        } actions: {
            Button("Add Location") {
                viewModel.showingAddLocation = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var locationListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(savedLocations) { location in
                    LocationCardView(location: location, viewModel: viewModel)
                        .contextMenu {
                            contextMenuItems(for: location)
                        }
                }
            }
            .padding()
        }
        .overlay {
            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    private var addButton: some View {
        Button {
            viewModel.showingAddLocation = true
        } label: {
            Image(systemName: "plus")
        }
        .disabled(!viewModel.canAddLocation(currentCount: savedLocations.count))
    }
    
    @ViewBuilder
    private func contextMenuItems(for location: SavedLocation) -> some View {
        Button {
            Task {
                await viewModel.refreshWeather(for: location)
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        
        Button {
            viewModel.setCurrentAsBaseline(for: location)
        } label: {
            Label("Set Current as Baseline", systemImage: "flag")
        }
        
        Divider()
        
        Button(role: .destructive) {
            viewModel.deleteLocation(location, context: modelContext)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
