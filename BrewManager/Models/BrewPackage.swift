//
//  Formula.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation

struct BrewPackage: Identifiable, Codable, Equatable {
    var id: String { token ?? name }
    let name: String
    let token: String?
    var version: String?
    let latestVersion: String?
    let homepage: String?
    let description: String?
    let tap: String?
    let type: BrewPackageType
    
    var isCask: Bool {
        return type == .cask
    }
    
    var isFormula: Bool {
        return type == .formula
    }
    
    init(fromFormula formulaInfo: BrewFormulaInfo) {
        self.name = formulaInfo.name ?? "Unknown"
        self.token = nil
        self.version = formulaInfo.installed.first?.version
        self.latestVersion = formulaInfo.versions.stable
        self.homepage = formulaInfo.homepage
        self.description = formulaInfo.desc
        self.tap = formulaInfo.tap
        self.type = .formula
    }
    
    init(fromCask caskInfo: BrewCaskInfo) {
        self.name = caskInfo.name?.first ?? caskInfo.token ?? "Unknown"
        self.token = caskInfo.token
        self.version = caskInfo.installed
        self.latestVersion = caskInfo.version
        self.homepage = caskInfo.homepage
        self.description = caskInfo.desc
        self.tap = caskInfo.tap
        self.type = .cask
    }
}


enum BrewPackageType: String, Codable, Equatable, Comparable {
    case formula
    case cask
    
    static func < (lhs: BrewPackageType, rhs: BrewPackageType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
