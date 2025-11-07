//
//  CheckForUpdatesViewModel.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 07/11/2025.
//

import Foundation
import Combine
import Sparkle

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
