//
//  HomeView.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
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
            HStack() {
                CardView(
                    title: "Homebrew Version",
                    value: store.brewVersion ?? "Unknown",
                    icon : Image("homebrew"),
                    actionIcon: Image(systemName: "arrow.trianglehead.2.clockwise"),
                    disabled: store.isUpdating
                ) {
                    store.send(.updateHomebrewRequested)
                }
                .padding([.trailing], 5)
                CardView(
                    title: "Installed Casks",
                    value: "\(store.totalInstalledCasks)",
                    icon : Image(systemName: "shippingbox.fill")
                )
                .padding([.trailing], 5)
                CardView(
                    title: "Installed Formulae",
                    value: "\(store.totalInstalledFormulae)",
                    icon : Image(systemName: "flask.fill")
                )
            }
            .padding(.bottom, 20)
            InstalledPackagesView()
        }
        .padding()
        .task {
            await store.send(.brewInfoLoaded).finish()
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
