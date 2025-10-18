    //
    //  InstalledPackagesFeature.swift
    //  BrewManager
    //
    //  Created by Izam on 17/10/2025.
    //

import Foundation
import ComposableArchitecture
import FactoryKit
import SwiftUI

@Reducer
struct InstalledPackagesFeature {
    
    @Injected(\.brewService) var brewService: HomebrewService
    
    @ObservableState
    struct State: Equatable {
        var installedPackages: [InstalledPackageState] = []
        var allPackages: [InstalledPackageState] = []
        var status: Status = .idle
        var sortOrder = [KeyPathComparator(\InstalledPackageState.installedPackage.name)]
        var searchText: String = ""
        
        var filteredPackages: [InstalledPackageState] {
            if searchText.isEmpty {
                return installedPackages
            }
            return installedPackages.filter {
                $0.installedPackage.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    enum Action: Equatable {
        case fetchInstalledPackages
        case installedPackagesResponse([BrewPackage])
        case sortChanged([KeyPathComparator<InstalledPackageState>])
        case searchTextChanged(String)
        case debouncedSearch
        case packageUpdateRequested(InstalledPackageState)
    }
    
    @Dependency(\.continuousClock) var clock
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchInstalledPackages:
                state.status = .loading
                return .run { send in
                    let result = await self.brewService.installedFormulas()
                    await send(.installedPackagesResponse(result))
                }
                
            case .installedPackagesResponse(let result):
                let packages = result.map { InstalledPackageState(installedPackage: $0) }
                state.installedPackages = packages
                state.allPackages = packages
                state.installedPackages.sort(using: state.sortOrder)
                state.status = .success
                return .none
                
            case .sortChanged(let sortOrder):
                state.sortOrder = sortOrder
                state.installedPackages.sort(using: sortOrder)
                return .none
                
            case .searchTextChanged(let searchText):
                state.searchText = searchText
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(500))
                    await send(.debouncedSearch)
                }
                .cancellable(id: "search", cancelInFlight: true)
                
            case .debouncedSearch:
                if state.searchText.isEmpty {
                    state.installedPackages = state.allPackages
                } else {
                    state.installedPackages = state.allPackages.filter {
                        $0.installedPackage.name.lowercased().contains(state.searchText.lowercased())
                    }
                }
                state.installedPackages.sort(using: state.sortOrder)
                return .none
                
            case .packageUpdateRequested(let package):
                let packgeIndex = state.installedPackages.firstIndex(where: { $0.id == package.id })
                guard let index = packgeIndex else { return .none }
                state.installedPackages[index].status = .loading
                return .run { send in
                    _ = await self.brewService.updatePackage(name: package.installedPackage.name)
                    await send(.fetchInstalledPackages)
                }
            }
        }
    }
}

struct InstalledPackageState: Equatable, Identifiable {
    var id: String { installedPackage.name }
    var installedPackage: BrewPackage
    var status: Status
    
    init(installedPackage: BrewPackage, status: Status = .idle) {
        self.installedPackage = installedPackage
        self.status = status
    }
}
