//
//  WeatherService.swift
//  WeatherClass1
//
//  Created by Wendell Richards on 1/15/26.
//

import Foundation

final class WeatherService{
    
    // This is the main function we will call from the ViewModel.
    // It does TWO GET requests:
    // 1) Geocoding: city name -> coordinates
    // 2) Forecast: coordinates -> weather
    
    
    
    func fetchCurrentWeather(forCity city:String) async throws -> (cityName:String , weather:CurrentWeather){
        
        let geocodingResult: GeoCodingResult = try await fetchCoordinates(forCity: city)
        
        let currentWeather: CurrentWeather = try await fetchWeather(latitude:geocodingResult.latitude,longitude:geocodingResult.longitude)
        
        return (geocodingResult.name,currentWeather)
        
    }
    
    
    // MARK: - Step 1: City -> Coordinates
        private func fetchCoordinates(forCity city:String) async throws -> GeoCodingResult{
        
            //Base URL
            var urlComponents: URLComponents? = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")

            // IF THERE IS A URL  == NIL
            if(urlComponents == nil){
                throw NetworkError.invalidUrl
            }
            
            
            //ADD PARAMETERS TO OUR URL
            urlComponents?.queryItems = [
                URLQueryItem(name:"name",value:city ),
                URLQueryItem(name:"count",value: "1"),
                URLQueryItem(name:"language", value: "en"),
                URLQueryItem(name: "format", value: "json")
                
            ]
            
            // Access the completed URL with Params
            let url: URL? = urlComponents?.url
            
            // Error Handling
            if url == nil {
                throw NetworkError.invalidUrl
            }

            
            // Fetch Information based on the prev URL
            let data: Data = try await performGetRequest(url: url!)
            
            let decoder: JSONDecoder = JSONDecoder()
            
            // Parse JSON into a Model an array of GeocodingResult
            let response: GeocodingResponse = try decoder.decode(GeocodingResponse.self, from: data)
            
            
            if let results: [GeoCodingResult] = response.results {
                if let firstResult: GeoCodingResult = results.first {
                    return firstResult
                }
            }
            
            throw NetworkError.noResults
            
        
        
        }
    
    
    // MARK: - Step 2: Coordinates -> Current Weather
    private func fetchWeather(latitude:Double, longitude:Double) async throws -> CurrentWeather{
        
        var urlComponents: URLComponents? = URLComponents(string: "https://api.open-meteo.com/v1/forecast")

        // IF THERE IS A URL  == NIL
        if(urlComponents == nil){
            throw NetworkError.invalidUrl
        }
        
        
        urlComponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "timezone", value: "auto"),


        ]
        
        let url: URL? = urlComponents?.url

        if url == nil {
            throw NetworkError.invalidUrl
        }
        
    
        let data:Data = try await performGetRequest(url: url!)
        
        let decoder: JSONDecoder = JSONDecoder()
        let response: ForecastResponse = try decoder.decode(ForecastResponse.self, from: data)
        
        return response.current_weather
        
    }
    
    
    
    // MARK: - The actual GET request (URLSession) CORE FUNCTION
    
    private func performGetRequest(url: URL) async throws -> Data {
        
        // STEP 1: Create a URLSession (the tool that makes network requests)
        let session: URLSession = URLSession.shared

        // STEP 2: Send a GET request to the URL and wait for the server to respond
        // - "try" because networking can fail
        // - "await" because it takes time
        let results: (Data,URLResponse) = try await session.data(from: url)
        
        // STEP 3: Split the result into:
        // - data: the actual content (usually JSON)
        // - response: information about the request (status code, headers, etc.)
        let data: Data = results.0
        let response: URLResponse = results.1
        
        // STEP 4: We want an HTTP response so we can read the status code (200, 404, 500...)
        // If this is not an HTTP response, something is wrong.
        
        if let httpResponse: HTTPURLResponse = response as? HTTPURLResponse{
            
            // STEP 5: Get the status code from the response
            let statusCode: Int = httpResponse.statusCode
            
            // STEP 6: Only treat 200–299 as success
            if statusCode < 200 || statusCode > 299{
                throw NetworkError.badStatusCode(statusCode: statusCode)
            }
            
            // STEP 7: If everything is successful, return the data
            return data
            
        }
        
        // EXTRA:
        // If we could not convert the response to HTTPURLResponse, it is not valid for our API use case
        throw NetworkError.invalidResponse
        
        
    }
    
    
    
    
    
    
    
    
    
}

// MARK: - Simple errors

enum NetworkError:Error {
    case invalidUrl
    case invalidResponse
    case badStatusCode(statusCode:Int)
    case noResults
}
