//
//  DiscoverFeature.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import Foundation
import ComposableArchitecture
import FactoryKit
import SwiftUI


@Reducer
struct DiscoverFeature {
    @Injected(\.brewSearchService) var brewSearchService: HomebrewSearchService
    @Injected(\.brewService) var brewService: HomebrewService
    
    @ObservableState
    struct State: Equatable {
        var searchQuery: String = ""
        var searchResults: [PackageState] = []
        var formulaeResults: [PackageState] = []
        var caskResults: [PackageState] = []
        var status: Status = .idle
        var selectedFilter: PackageFilter = .all
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action {
        case searchQueryChanged(String)
        case searchCompleted(results: [BrewPackage])
        case filterChanged(PackageFilter)
        case installPackage(BrewPackage, force: Bool)
        case installationCompleted(BrewPackage, Result<Void, BrewError>)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case installError(PackageState)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .searchQueryChanged(let query):
                enum CancelID { case search }
                
                guard state.searchQuery != query else {
                    return .none
                }
                guard !query.isEmpty else {
                    state.searchResults = []
                    state.formulaeResults = []
                    state.caskResults = []
                    state.status = .idle
                    return .none
                }
                state.status = .loading
                state.searchQuery = query
                return .run {[searchQuery = state.searchQuery] send in
                    let results = await self.brewSearchService
                        .searchPackages(query: searchQuery)
                    await send(.searchCompleted(results: results))
                }
                .debounce(id: CancelID.search, for: 0.7, scheduler: DispatchQueue.main)
                .cancellable(id: CancelID.search, cancelInFlight: true)
                
            case .searchCompleted(let results):
                state.searchResults = results.map { PackageState(package: $0) }
                state.formulaeResults = state.searchResults.filter { $0.package.type == .formula }
                state.caskResults = state.searchResults.filter { $0.package.type == .cask }
                print("Search completed with \(results.count) results.")
                state.status = .success()
                return .none
                
            case .filterChanged(let filter):
                state.selectedFilter = filter
                return .none
            
            case .installPackage(let package, let force):
                updatePackageStatus(state: &state, package: package, status: .loading)
                return .run { send in
                    let result = try await self.brewService
                        .installPackage(package, force: force)
                    await send(.installationCompleted(package, result))
                }
                
            case .installationCompleted(let package, let result):
                switch result {
                case .success():
                    updatePackageStatus(state: &state, package: package, status: .success())
                case .failure(let error):
                    updatePackageStatus(state: &state, package: package, status: .idle)
                    state.alert = AlertState(
                        title: {
                            TextState("Installation Error")
                        },
                        actions: {
                            ButtonState<Action.Alert>(
                                role: .cancel,
                                label: {
                                    TextState("Cancel")
                                })
                        },
                        message: {
                            TextState("Failed to install \(package.name). \n\(error.localizedDescription)")
                        },
                    )
                }
                return .none
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    private func updatePackageStatus(state: inout State, package: BrewPackage, status: Status) {
        let packageState = PackageState(package: package)
        if let index = state.searchResults.firstIndex(where: { $0.id == packageState.id }) {
            state.searchResults[index].status = status
        }
        
        if let index = state.formulaeResults.firstIndex(where: { $0.id == packageState.id }) {
            state.formulaeResults[index].status = status
        }
        
        if let index = state.caskResults.firstIndex(where: { $0.id == packageState.id }) {
            state.caskResults[index].status = status
        }
    }
    
    private func getPackageIndex(state: State,
                                 package: PackageState) -> Int? {
        return state.searchResults.firstIndex(where: { $0.id == package.id })
    }
    
}


enum PackageFilter: String, Identifiable, Hashable, CaseIterable  {
    case all = "All"
    case formulae = "Formulae"
    case casks = "Casks"
    var id: Self { self }
}
