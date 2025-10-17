//
//  HomeFeature.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import Foundation
import ComposableArchitecture
import FactoryKit

@Reducer
struct HomeFeature {
    
    @Injected(\.brewService) var brewService: HomebrewService
    
    @ObservableState
    struct State: Equatable {
        var brewVersion: String?
        var status: Status = .idle
        var isUpdating: Bool = false
        var updateMessage: String?
        var updateAlertTitle: String = ""
        var showUpdateAlert: Bool = false
        var updateIsAlreadyUpToDate: Bool = false
    }
    
    enum Action {
        case brewInfoLoaded
        case brewInfoLoadSuccess(version: String)
        case updateHomebrewRequested
        case updateHomebrewCompleted(success: Bool, message: String, alreadyUpToDate: Bool)
        case dismissUpdateAlert
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .brewInfoLoaded:
                state.status = .loading
                return .run { send in
                    let version = await self.brewService.getBrewVersion()
                    await send(.brewInfoLoadSuccess(version: version ?? "Unknown"))
                }
            case .brewInfoLoadSuccess(version: let version):
                state.brewVersion = version
                state.status = .success
                return .none
                
            case .updateHomebrewRequested:
                state.isUpdating = true
                return .run { send in
                    let result = await self.brewService.updateHomebrew()
                    await send(.updateHomebrewCompleted(
                        success: result.success,
                        message: result.message,
                        alreadyUpToDate: result.alreadyUpToDate
                    ))
                }
                
            case let .updateHomebrewCompleted(success, message, alreadyUpToDate):
                state.isUpdating = false
                state.updateMessage = message
                state.updateAlertTitle = alreadyUpToDate ? "Already Up to Date" : "Update Complete"
                state.showUpdateAlert = true
                state.updateIsAlreadyUpToDate = alreadyUpToDate
                if success && !alreadyUpToDate {
                    return .send(.brewInfoLoaded)
                }
                return .none
                
            case .dismissUpdateAlert:
                state.showUpdateAlert = false
                state.updateMessage = nil
                state.updateAlertTitle = ""
                return .none
            }
        }
    }
    
}
