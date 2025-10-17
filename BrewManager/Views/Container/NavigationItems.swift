//
//  NavigationItems.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import FactoryKit

enum NavigationItems: CaseIterable {
    case home
    
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        }
    }
    var systemImageName: String {
        switch self {
        case .home:
            return "house.fill"
        }
    }
    
    var view: some View {
        switch self {
        case .home:
            HomeView()
        }
    }
}
