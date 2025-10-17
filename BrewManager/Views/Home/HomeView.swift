//
//  HomeView.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import SwiftUI
import ComposableArchitecture
import FactoryKit

struct HomeView: View {
    @InjectedObject(\.homeFeature) private var store: StoreOf<HomeFeature>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to BrewManager!")
                .font(.largeTitle)
            Text("Manage your Homebrew packages with ease.")
                .font(.subheadline)
                .padding(.bottom, 20)
            HStack(alignment: .firstTextBaseline) {
                Image("homebrew")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                Text("Homebrew version is: \(store.brewVersion ?? "Unknown")")
                    .font(.title3)
                Spacer()
                if store.isUpdating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.4)
                }
                Button("Update Homebrew", systemImage: "arrow.trianglehead.2.clockwise") {
                    store.send(.updateHomebrewRequested)
                }
                .disabled(store.isUpdating)
            }
            .padding(.bottom, 20)
            Text("Installed Formulas & Casks")
                .font(.title2)
                .padding(.bottom, 10)
            InstalledPackagesView()
        }
        .task {
            store.send(.brewInfoLoaded)
        }
        .alert(
            store.updateAlertTitle,
            isPresented: Binding(
                get: { store.showUpdateAlert },
                set: { if !$0 { store.send(.dismissUpdateAlert) } }
            )
        ) {
            Button("OK") {
                store.send(.dismissUpdateAlert)
            }
        } message: {
            Text(store.updateMessage ?? "")
        }
    }
}

#Preview {
    HomeView()
}
