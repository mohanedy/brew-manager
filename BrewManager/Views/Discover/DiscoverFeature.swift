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
        var formulaeResults: [PackageState] {
            searchResults.filter { $0.package.type == .formula }
        }
        var caskResults: [PackageState] {
            searchResults.filter { $0.package.type == .cask }
        }
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
                print("Search completed with \(results.count) results.")
                state.status = .success()
                return .none
                
            case .filterChanged(let filter):
                state.selectedFilter = filter
                return .none
            
            case .installPackage(let package, let force):
                guard let index = getPackageIndex(state: state, package: PackageState(package: package)) else {
                    return .none
                }
                state.searchResults[index].status = .loading
                return .run { send in
                    let result = try await self.brewService
                        .installPackage(package, force: force)
                    await send(.installationCompleted(package, result))
                }
                
            case .installationCompleted(let package, let result):
                guard let index = getPackageIndex(state: state, package: PackageState(package: package)) else {
                    return .none
                }
                switch result {
                case .success():
                    state.searchResults[index].status = .success()
                case .failure(let error):
                    state.searchResults[index].status = .idle
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
