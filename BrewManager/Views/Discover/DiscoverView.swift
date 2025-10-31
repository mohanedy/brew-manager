//
//  DiscoverView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 24/10/2025.
//

import SwiftUI
import ComposableArchitecture
import FactoryKit

struct DiscoverView: View {
    @InjectedObject(\.discoverFeature) private var store: StoreOf<DiscoverFeature>
    
    private var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 200), spacing: 20),
    ]
    
    
    var body: some View {
        ScrollView {
            contentView
        }
        .navigationTitle("Discover")
        .background(.clear)
        .searchable(
            text: $store.searchQuery.sending(\.searchQueryChanged),
            prompt: "Search Formulae and Casks",
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("Filter", selection: $store.selectedFilter.sending(\.filterChanged)) {
                    ForEach(PackageFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack {
            if store.status == .idle {
                idleStateView
            } else if store.status == .loading {
                loadingStateView
            } else if store.status == .success() && store.searchResults.isEmpty {
                noResultsView
            } else {
                resultsGridView
            }
        }
    }
    
    @ViewBuilder
    private var idleStateView: some View {
        Spacer()
        Text("Start typing to search for Formulae and Casks")
            .foregroundStyle(.secondary)
            .padding()
        Spacer()
    }
    
    @ViewBuilder
    private var loadingStateView: some View {
        Spacer()
        ProgressView()
            .scaleEffect(1)
            .padding()
        Spacer()
    }
    
    @ViewBuilder
    private var noResultsView: some View {
        Spacer()
        Text("No results found")
            .foregroundStyle(.secondary)
            .padding()
        Spacer()
    }
    
    @ViewBuilder
    private var resultsGridView: some View {
        LazyVGrid(
            columns: columns,
            alignment: .center,
            spacing: 16
        ) {
            if !store.formulaeResults.isEmpty && (store.selectedFilter != .casks || store.selectedFilter == .all) {
                Section {
                    ForEach(store.formulaeResults) { item in
                        PackageCardView(
                            packageState: item
                        ) { forceInstall in
                            installPackage(item.package, forceInstall: forceInstall)
                        }
                    }
                } header: {
                    section(title: "Formulae")
                }
            }
            if !store.caskResults.isEmpty && (store.selectedFilter != .formulae || store.selectedFilter == .all) {
                Section {
                    ForEach(store.caskResults) { item in
                        PackageCardView(
                            packageState: item
                        ) { forceInstall in
                            installPackage(item.package, forceInstall: forceInstall)
                        }
                    }
                } header: {
                    section(title: "Casks")
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func section(title: String) -> some View {
        Text(title)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .leading], 8)
    }
    
    private func installPackage(_ package: BrewPackage, forceInstall: Bool) {
        store.send(.installPackage(package, force: forceInstall))
    }
}

#Preview {
    DiscoverView()
        .frame(width: 800, height: 500)
}


