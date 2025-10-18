    //
    //  InstalledPackagesView.swift
    //  BrewManager
    //
    //  Created by Izam on 17/10/2025.
    //

import SwiftUI
import ComposableArchitecture
import FactoryKit

struct InstalledPackagesView: View {
    @InjectedObject(\.installedPackagesFeature) private var store: StoreOf<InstalledPackagesFeature>
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("Installed Packages")
                    .font(.title2)
                    .bold()
                Spacer()
                if store.status == .loading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
                Button("Refresh", systemImage: "arrow.clockwise") {
                    store.send(.fetchInstalledPackages)
                }.disabled(store.status == .loading)
                
                
                Button("Upgrade All", systemImage: "arrow.up.circle") {
                    store.send(.fetchInstalledPackages)
                }.disabled(store.status == .loading)
                
            }.padding([.bottom], 5)
            packagesTable()
                .task {
                    store.send(.fetchInstalledPackages)
                }
        }
        .searchable(text: $store.searchText.sending(\.searchTextChanged),
                    prompt: "Search Installed Formulae and Casks")
    }
    
    @ViewBuilder
    private func packagesTable() -> some View {
        Table(store.filteredPackages,
              sortOrder: $store.sortOrder.sending(\.sortChanged)) {
            TableColumn("Name", value: \.installedPackage.name)
            TableColumn("Type", value: \.installedPackage.type.rawValue)
            TableColumn("Version", value: \.installedPackage.version)
            TableColumn("Latest Version" ) { packageState in
                Text(packageState.installedPackage.latestVersion ?? "N/A")
            }
            TableColumn("Actions") { packageState in
                let formula = packageState.installedPackage
                HStack {
                    Button {
                        print("Update \(formula.name) tapped")
                    } label: {
                        Image(systemName: "arrow.up.circle")
                    }
                    .help("Update Package")
                    .disabled(formula.latestVersion == nil || formula.latestVersion == formula.version)
                    
                    Button {
                        print("remove \(formula.name) tapped")
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .help("Uninstall Package")
                    
                    Button {
                        if let url = URL(string: formula.homepage ?? "") {
                            NSWorkspace.shared.open(url)
                        }
                        
                    } label: {
                        Image(systemName: "safari")
                            .foregroundColor(.blue)
                    }
                    .help("Visit Package Page")
                }
            }
        }
    }
    
}

#Preview {
    InstalledPackagesView()
}
