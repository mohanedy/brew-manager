//
//  NavigationItems.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import FactoryKit

enum NavigationItems: CaseIterable {
    case home
    case discover
    case about
    case settings
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .discover:
            return "Discover"
        case .about:
            return "About"
        case .settings:
            return "Settings"
        }
    }
    var systemImageName: String {
        switch self {
        case .home:
            return "house.fill"
        case .discover:
            return "magnifyingglass"
        case .about:
            return "info.circle.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    static var mainNavigationItems: [NavigationItems] {
        return [.home, .discover]
    }
}
