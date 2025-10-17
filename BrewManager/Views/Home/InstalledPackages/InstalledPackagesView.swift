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
        Table(store.installedPackages) {
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
        .task {
             store.send(.fetchInstalledPackages)
        }
    }
}

#Preview {
    InstalledPackagesView()
}
