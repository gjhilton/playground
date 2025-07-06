//
//  Models.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Tour Location Model
struct TourLocation {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let contentFragments: [ContentFragment]
    let audioFile: String?
    let imageFile: String?
    let isVisited: Bool
    let progress: Double // 0.0 to 1.0
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, contentFragments: [ContentFragment] = [], audioFile: String? = nil, imageFile: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.contentFragments = contentFragments
        self.audioFile = audioFile
        self.imageFile = imageFile
        self.isVisited = false
        self.progress = 0.0
    }
}

// MARK: - Content Fragment Model
struct ContentFragment: Codable {
    let id: String
    let type: ContentType
    let text: String
    let audioFile: String?
    let imageFile: String?
    let duration: TimeInterval // For auto-play timing
    
    enum ContentType: String, Codable {
        case narration
        case bookExtract
        case image
        case historicalNote
    }
}

// MARK: - Chapter Model
struct Chapter: Codable {
    let id: String
    let title: String
    let content: String
    let audioFile: String?
    let imageFile: String?
}

// MARK: - App State
class AppState: ObservableObject {
    static let shared = AppState()
    
    var currentMode: TourMode = .promenade
    var currentLocation: TourLocation?
    var visitedLocations: Set<String> = []
    var locationProgress: [String: Double] = [:]
    var userLocation: CLLocation?
    var locationServicesEnabled: Bool = false
    
    enum TourMode {
        case promenade
        case parlour
    }
    
    private init() {}
    
    func markLocationVisited(_ locationId: String) {
        visitedLocations.insert(locationId)
    }
    
    func updateLocationProgress(_ locationId: String, progress: Double) {
        locationProgress[locationId] = min(1.0, max(0.0, progress))
    }
    
    func getLocationProgress(_ locationId: String) -> Double {
        return locationProgress[locationId] ?? 0.0
    }
}

// MARK: - Tour Data
class TourData {
    static let shared = TourData()
    
    let locations: [TourLocation] = [
        TourLocation(
            id: "A",
            name: "Whitby Station",
            address: "Station Square, Whitby, North Yorkshire, YO21 1YN",
            latitude: 54.4858,
            longitude: -0.6206,
            contentFragments: generatePlaceholderContent(for: "Whitby Station")
        ),
        TourLocation(
            id: "B",
            name: "Whitby Museum",
            address: "Pannett Park, Whitby, North Yorkshire, YO21 1RE",
            latitude: 54.4853,
            longitude: -0.6133,
            contentFragments: generatePlaceholderContent(for: "Whitby Museum")
        ),
        TourLocation(
            id: "C",
            name: "6 Royal Crescent",
            address: "6 Royal Crescent, Whitby, North Yorkshire, YO21 3EJ",
            latitude: 54.4857,
            longitude: -0.6147,
            contentFragments: generatePlaceholderContent(for: "6 Royal Crescent")
        ),
        TourLocation(
            id: "D",
            name: "Swing Bridge",
            address: "Bridge St, Whitby YO22 4BG",
            latitude: 54.4855,
            longitude: -0.6167,
            contentFragments: generatePlaceholderContent(for: "Swing Bridge")
        ),
        TourLocation(
            id: "E",
            name: "St Mary's Church",
            address: "Abbey Plain, Whitby YO22 4JR",
            latitude: 54.4858,
            longitude: -0.6089,
            contentFragments: generatePlaceholderContent(for: "St Mary's Church")
        )
    ]
    
    let chapters: [Chapter] = [
        Chapter(id: "1", title: "Chapter 1: Jonathan Harker's Journal", content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", audioFile: nil, imageFile: nil),
        Chapter(id: "2", title: "Chapter 2: Mina Murray's Journal", content: "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.", audioFile: nil, imageFile: nil),
        Chapter(id: "3", title: "Chapter 3: Dr. Seward's Diary", content: "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.", audioFile: nil, imageFile: nil)
    ]
    
    private init() {}
    
    func getLocation(by id: String) -> TourLocation? {
        return locations.first { $0.id == id }
    }
    
    func getNextLocation(after currentId: String) -> TourLocation? {
        guard let currentIndex = locations.firstIndex(where: { $0.id == currentId }) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < locations.count ? locations[nextIndex] : nil
    }
}

// MARK: - Helper Functions
private func generatePlaceholderContent(for location: String) -> [ContentFragment] {
    return [
        ContentFragment(
            id: "\(location)_1",
            type: .narration,
            text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            audioFile: nil,
            imageFile: nil,
            duration: 5.0
        ),
        ContentFragment(
            id: "\(location)_2",
            type: .bookExtract,
            text: "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
            audioFile: nil,
            imageFile: nil,
            duration: 8.0
        ),
        ContentFragment(
            id: "\(location)_3",
            type: .historicalNote,
            text: "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
            audioFile: nil,
            imageFile: nil,
            duration: 6.0
        )
    ]
} 