//
//  CheckForUpdatesView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 18/10/2025.
//

import SwiftUI
import Sparkle

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
