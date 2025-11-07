//
//  CheckForUpdatesView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 18/10/2025.
//

import SwiftUI
import Sparkle
import Combine

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}


struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button(
            "Check for Updates…",
            systemImage: "arrow.trianglehead.2.clockwise",
            action: updater.checkForUpdates
        )
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}
