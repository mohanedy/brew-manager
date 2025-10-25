//
//  Container.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation
import FactoryKit
import ComposableArchitecture

extension Container {
    @MainActor
    var commandService: Factory<CommandService> {
        self { @MainActor in DefaultCommandService() }
            .singleton
    }
    
    @MainActor
    var networkService: Factory<NetworkService> {
        self { @MainActor in DefaultNetworkService() }
            .singleton
    }
    
    @MainActor
    var brewService: Factory<HomebrewService> {
        self { @MainActor in DefaultHomebrewService() }
            .singleton
    }
    
    @MainActor
    var brewSearchService: Factory<HomebrewSearchService> {
        self { @MainActor in DefaultHomebrewSearchService() }
            .singleton
    }
    
    @MainActor
    var homeFeature: Factory<StoreOf<HomeFeature>> {
        self { @MainActor in
            Store(initialState: HomeFeature.State()) {
                HomeFeature()
            }
        }
    }
    
    @MainActor
    var installedPackagesFeature: Factory<StoreOf<InstalledPackagesFeature>> {
        self { @MainActor in
            Store(initialState: InstalledPackagesFeature.State()) {
                InstalledPackagesFeature()
            }
        }
    }
    
    @MainActor
    var discoverFeature: Factory<StoreOf<DiscoverFeature>> {
        self { @MainActor in
            Store(initialState: DiscoverFeature.State()) {
                DiscoverFeature()
            }
        }
    }
}
