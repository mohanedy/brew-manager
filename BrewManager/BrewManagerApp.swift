//
//  BrewManagerApp.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import SwiftUI
import SwiftData
import AppKit
import Sparkle

@main
struct BrewManagerApp: App {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
                CommandGroup(after: .appInfo) {
                    CheckForUpdatesView(updater: updaterController.updater)
                }
            }
    }
}
