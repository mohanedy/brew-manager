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
    @Dependency(\.continuousClock) var clock
    
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
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action: Equatable {
        case fetchInstalledPackages
        case installedPackagesResponse([BrewPackage])
        case sortChanged([KeyPathComparator<InstalledPackageState>])
        case searchTextChanged(String)
        case debouncedSearch
        case packageUpdateRequested(InstalledPackageState)
        case packageUpdateCompleted(InstalledPackageState)
        case packageDeleteRequested(InstalledPackageState)
        case alert(PresentationAction<Alert>)
        case updateAllPackagesRequested
        case packageUpgradeUpdate(BrewUpgradeStatus)
        case upgradeAllCompleted(Bool)
        
        enum Alert: Equatable {
            case deleteConfirmed(InstalledPackageState)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchInstalledPackages:
                return fetchInstalledPackages(state: &state)
                
            case .installedPackagesResponse(let result):
                return installedPackagesResponse(state: &state, result: result)
                
            case .sortChanged(let sortOrder):
                return sortChanged(state: &state, sortOrder: sortOrder)
                
            case .searchTextChanged(let searchText):
                return searchTextChanged(state: &state, searchText: searchText)
                
            case .debouncedSearch:
                return debouncedSearch(state: &state)
                
            case .packageUpdateRequested(let package):
                return packageUpdateRequested(state: &state, package: package)
                
            case .packageUpdateCompleted(let package):
                return packageUpdateCompleted(state: &state, package: package)
                
            case .packageDeleteRequested(let package):
                return onDeletePackageRequested(state: &state, package: package)
                
            case .updateAllPackagesRequested:
                return onUpdateAllPackagesRequested(state: &state)
                
            case .packageUpgradeUpdate(let update):
                return onPackageUpgradeUpdate(state: &state, update: update)
                
            case .upgradeAllCompleted(let success):
                return onUpgradeAllCompleted(state: &state, success: success)
                
            case .alert(.presented(.deleteConfirmed(let package))):
                return onDeletePackageConfirmed(state: &state, package: package)
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    // MARK: - Actions Handlers
    
    private func fetchInstalledPackages(state: inout State) -> Effect<Action> {
        state.status = .loading
        return .run { send in
            let result = await self.brewService.installedFormulas()
            await send(.installedPackagesResponse(result))
        }
    }
    
    private func installedPackagesResponse(state: inout State,
                                           result: [BrewPackage])
    -> Effect<Action> {
        let packages = result.map { InstalledPackageState(installedPackage: $0) }
        state.installedPackages = packages
        state.allPackages = packages
        state.installedPackages.sort(using: state.sortOrder)
        state.status = .success()
        return .none
    }
    
    private func sortChanged(state: inout State,
                             sortOrder: [KeyPathComparator<InstalledPackageState>])
    -> Effect<Action> {
        state.sortOrder = sortOrder
        state.installedPackages.sort(using: sortOrder)
        return .none
    }
    
    private func searchTextChanged(state: inout State, searchText: String)
    -> Effect<Action> {
        state.searchText = searchText
        return .run { send in
            try await self.clock.sleep(for: .milliseconds(500))
            await send(.debouncedSearch)
        }
        .cancellable(id: "search", cancelInFlight: true)
    }
    
    private func debouncedSearch(state: inout State) -> Effect<Action> {
        if state.searchText.isEmpty {
            state.installedPackages = state.allPackages
        } else {
            state.installedPackages = state.allPackages.filter {
                $0.installedPackage.name.lowercased().contains(state.searchText.lowercased())
            }
        }
        state.installedPackages.sort(using: state.sortOrder)
        return .none
    }
    
    private func packageUpdateRequested(state: inout State,
                                        package: InstalledPackageState)
    -> Effect<Action> {
        let packageIndex = getPackageIndex(state: state, package: package)
        guard let index = packageIndex else { return .none }
        state.installedPackages[index].status = .loading
        return .run { send in
            _ = await self.brewService.updatePackage(package: package.installedPackage)
            await send(.packageUpdateCompleted(package))
            try await self.clock.sleep(for: .seconds(2))
            await send(.fetchInstalledPackages)
        }
    }
    
    private func packageUpdateCompleted(state: inout State,
                                        package: InstalledPackageState)
    -> Effect<Action> {
        let packageIndex = getPackageIndex(state: state, package: package)
        guard let index = packageIndex else { return .none }
        state.installedPackages[index].status = .success(.updated)
        return .none
    }
    
    private func onDeletePackageRequested(state: inout State,
                                          package: InstalledPackageState)
    -> Effect<Action> {
        state.alert = AlertState(
            title: {
                TextState("Confirm Uninstall")
            },
            actions: {
                ButtonState<Action.Alert>(
                    role: .destructive,
                    action: .deleteConfirmed(package),
                    label: {
                        TextState("Uninstall")
                    })
                
                ButtonState<Action.Alert>(
                    role: .cancel,
                    label: {
                        TextState("Cancel")
                    })
                
            },
            message: {
                TextState("Are you sure you want to uninstall \(package.installedPackage.name)?")
            }
        )
        
        return .none
    }
    
    private func onDeletePackageConfirmed(state: inout State,
                                          package: InstalledPackageState)
    -> Effect<Action> {
        let packageIndex = getPackageIndex(state: state, package: package)
        guard let index = packageIndex else { return .none }
        state.installedPackages[index].status = .loading
        return .run { send in
            _ = await self.brewService.delete(package: package.installedPackage)
            await send(.fetchInstalledPackages)
        }
    }
    
    private func getPackageIndex(state: State,
                                 package: InstalledPackageState) -> Int? {
        return state.installedPackages.firstIndex(where: { $0.id == package.id })
    }
    
    private func onUpdateAllPackagesRequested(state: inout State)
    -> Effect<Action> {
        state.status = .loading
        return .run { send in
            let success = await self.brewService.upgradeAllPackagesWithStreaming { update in
                Task { @MainActor in
                    send(.packageUpgradeUpdate(update))
                }
            }
            await send(.upgradeAllCompleted(success))
        }
    }
    
    private func onPackageUpgradeUpdate(state: inout State, update: BrewUpgradeStatus)
    -> Effect<Action> {
        switch update {
        case .packageFetching(let name):
            // Mark package as fetching/loading
            if let index = state.installedPackages.firstIndex(where: { $0.installedPackage.name == name }) {
                state.installedPackages[index].status = .loading
            }
            
        case .packageUpgrading(let name, _, _):
            // Mark package as upgrading
            if let index = state.installedPackages.firstIndex(where: { $0.installedPackage.name == name }) {
                state.installedPackages[index].status = .loading
            }
            
        case .packageCompleted(let name):
            // Mark package as completed
            if let index = state.installedPackages.firstIndex(where: { $0.installedPackage.name == name }) {
                state.installedPackages[index].status = .success(.updated)
            }
        }
        
        return .none
    }
    
    private func onUpgradeAllCompleted(state: inout State, success: Bool)
    -> Effect<Action> {
        state.status = success ? .success() : .failure
        // Refresh the package list to get updated versions
        return .run { send in
            await send(.fetchInstalledPackages)
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
