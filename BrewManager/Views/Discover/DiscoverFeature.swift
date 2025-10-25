//
//  DiscoverFeature.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import Foundation
import ComposableArchitecture
import FactoryKit

@Reducer
struct DiscoverFeature {
    @Injected(\.brewSearchService) var brewService: HomebrewSearchService
    @Dependency(\.continuousClock) var clock
    
    @ObservableState
    struct State: Equatable {
        var searchQuery: String = ""
        var searchResults: [BrewPackage] = []
        var formulaeResults: [BrewPackage] {
            searchResults.filter { $0.type == .formula }
        }
        var caskResults: [BrewPackage] {
            searchResults.filter { $0.type == .cask }
        }
        var status: Status = .idle
    }
    
    enum Action {
        case searchQueryChanged(String)
        case performSearch
        case searchCompleted(results: [BrewPackage])
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .searchQueryChanged(let query):
                state.searchQuery = query
                return .run { send in
                    try await self.clock.sleep(for: .milliseconds(700))
                    await send(.performSearch)
                }
                .cancellable(id: "search", cancelInFlight: true)
            case .performSearch:
                guard !state.searchQuery.isEmpty else {
                    state.searchResults = []
                    state.status = .idle
                    return .none
                }
                state.status = .loading
                let searchQuery = state.searchQuery
                return .run { send in
                    let results = await self.brewService.searchPackages(query: searchQuery)
                    await send(.searchCompleted(results: results))
                }
            case .searchCompleted(let results):
                state.searchResults = results
                print("Search completed with \(results.count) results.")
                state.status = .success()
                return .none
            }
        }
    }
    
    
}

