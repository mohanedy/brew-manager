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
    
    @ObservableState
    struct State: Equatable {
        var installedPackages: [InstalledPackageState] = []
        var status: Status = .idle
    }
    
    enum Action: Equatable {
        case fetchInstalledPackages
        case installedPackagesResponse([BrewPackage])
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchInstalledPackages:
                state.status = .loading
                return .run { send in
                    let result = await self.brewService.installedFormulas()
                    await send(.installedPackagesResponse(result))
                }
            case .installedPackagesResponse(let result):
                state.installedPackages = result.map { InstalledPackageState(installedPackage: $0) }
                    .sorted { $0.installedPackage.name.lowercased() < $1.installedPackage.name.lowercased() }
                state.status = .success
                return .none
            }
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
