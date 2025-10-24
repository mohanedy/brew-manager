//
//  Status.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import Foundation

enum Status: Equatable {
    case idle
    case loading
    case success(_ actionType: ActionType? = nil)
    case failure
}

enum ActionType {
    case updated
    case removed
    case installed
    case loaded
}
