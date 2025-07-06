//
//  Protocols.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import Foundation
import CoreLocation
// NOTE: Models.swift must be included in the target for TourLocation and Chapter to be available.

// MARK: - Navigation Delegate
protocol DracumentaryNavigationDelegate: AnyObject {
    func navigateToMenu()
    func navigateToPromenade()
    func navigateToParlour()
    func navigateToExtras()
    func navigateToHelp()
    func navigateToCaution()
    func navigateToTourMap()
    func navigateToLocationContent(_ location: TourLocation)
    func navigateToChapters()
    func navigateToChapter(_ chapter: Chapter)
    func navigateToRecreations()
    func navigateToCredits()
    func navigateBack()
}

// MARK: - Location Services Delegate
protocol LocationServicesDelegate: AnyObject {
    func locationDidUpdate(_ location: CLLocation)
    func locationDidFailWithError(_ error: Error)
    func authorizationStatusDidChange(_ status: CLAuthorizationStatus)
}

// MARK: - Audio Player Delegate
protocol AudioPlayerDelegate: AnyObject {
    func audioDidStartPlaying()
    func audioDidFinishPlaying()
    func audioDidPause()
    func audioDidResume()
    func audioDidFailWithError(_ error: Error)
}

// MARK: - Resource Provider
protocol ResourceProvider {
    /// Loads data for a resource with the given name and extension (e.g., "Help", "html"). Returns nil if not found.
    func data(forResource name: String, withExtension ext: String) -> Data?
    /// Loads a URL for a resource with the given name and extension, if available.
    func url(forResource name: String, withExtension ext: String) -> URL?
} 