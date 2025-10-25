//
//  BrewInfoResponse.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 17/10/2025.
//

import Foundation

struct BrewInfoResponse: Codable {
    let formulae: [BrewFormulaInfo]
    let casks: [BrewCaskInfo]
}

struct BrewFormulaInfo: Codable {
    let name: String?
    let versions: BrewVersions
    let installed: [BrewInstalledVersion]
    let homepage: String?
    let desc: String?
    let tap: String?
}

struct BrewVersions: Codable {
    let stable: String?
}

struct BrewInstalledVersion: Codable {
    let version: String?
}

struct BrewCaskInfo: Codable {
    let token: String?
    let name: [String]?
    let homepage: String?
    let installed: String?
    let version: String?
    let desc: String?
    let tap: String?
}
    
