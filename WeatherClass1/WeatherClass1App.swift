//
//  WeatherClass1App.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import SwiftUI
import SwiftData

@main
struct WeatherClass1App: App {
    var body: some Scene {
        WindowGroup {
            WeatherView()
        }
        .modelContainer(for: SavedLocation.self)
    }
}

