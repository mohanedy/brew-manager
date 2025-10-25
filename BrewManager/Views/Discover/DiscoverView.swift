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
        GridItem(.adaptive(minimum: 200), spacing: 16),
    ]
    
    
    var body: some View {
        ScrollView {
            VStack {
                if store.status == .idle {
                    Spacer()
                    Text("Start typing to search for Formulae and Casks")
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else if store.status == .loading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1)
                        .padding()
                    Spacer()
                } else if store.status == .success() && store.searchResults.isEmpty {
                    Spacer()
                    Text("No results found")
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else {
                    LazyVGrid(
                        columns: columns,
                        alignment: .center,
                        spacing: 16,
                    ) {
                        if !store.formulaeResults.isEmpty {
                            Section {
                                ForEach(store.formulaeResults) { item in
                                    PackageCardView(package: item)
                                }
                            } header: {
                                section(title: "Formulae")
                            }
                        }
                        if !store.caskResults.isEmpty {
                            Section {
                                ForEach(store.caskResults) { item in
                                    PackageCardView(package: item)
                                }
                            } header: {
                                section(title: "Casks")
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Discover")
        .background(.clear)
        .searchable(text: $store.searchQuery.sending(\.searchQueryChanged),
                    prompt: "Search Formulae and Casks")
    }

    @ViewBuilder
    private func section(title: String) -> some View {
        Text(title)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .leading], 8)
    }
}

#Preview {
    DiscoverView()
}
