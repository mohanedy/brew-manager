//
//  Formula.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation

struct BrewPackage: Identifiable, Codable, Equatable {
    var id: String { name }
    let name: String
    let token: String?
    let version: String
    let latestVersion: String?
    let homepage: String?
    let type: BrewPackageType
}


enum BrewPackageType: String, Codable, Equatable {
    case formula
    case cask
}
