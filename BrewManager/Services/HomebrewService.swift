//
//  HomebrewServices.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation
import FactoryKit

protocol HomebrewService {
    func getBrewVersion() async -> String?
    func updateHomebrew() async -> (success: Bool, message: String, alreadyUpToDate: Bool)
    func installedFormulas() async -> [BrewPackage]
    func updatePackage(name: String) async -> Bool
    func totalIntalledPackages(type: BrewPackageType) async -> Int
    func delete(package: BrewPackage) async -> Bool
    func upgradeAllPackages() async -> Bool
    //    func installedPackages() -> [String]
    //    func installPackage(name: String) -> Bool
    //    func uninstallPackage(name: String) -> Bool
    //    func updatePackage(name: String) -> Bool
    //    func upgradeAllPackages() -> Bool
}


class DefaultHomebrewService: HomebrewService {
    
    init() {}
    
    private var brewPath: String = "/opt/homebrew/bin/brew"
    @Injected(\.commandService) private var commandService: CommandService
    
    func getBrewVersion() async -> String? {
        let commandResult = await commandService.runCommand("--version", path: brewPath)
        print(commandResult)
        if let output = commandResult.output, !output.isEmpty {
            let components = output.split(separator: " ")
            if components.count >= 2 {
                let version = String(components[1])
                
                if let dashRange = version.range(of: "-") {
                    return String(version[..<dashRange.lowerBound])
                }
                
                return version
            }
        }
        
        return nil
    }
    
    func updateHomebrew() async -> (success: Bool, message: String, alreadyUpToDate: Bool)  {
        let commandResult = await commandService.runCommand("update", path: brewPath)
        
        if let output = commandResult.output {
            // Check if already up to date
            if output.contains("Already up-to-date") || output.contains("already up to date") {
                return (true, "Homebrew is already up to date!", true)
            }
            
            // Check for successful update
            if output.contains("Updated") || output.contains("updated")
                || commandResult.error == nil || commandResult.error?.isEmpty == true {
                return (true, "Homebrew updated successfully!", false)
            }
        }
        
        // Handle errors
        if let error = commandResult.error, !error.isEmpty {
            return (false, "Update failed: \(error)", false)
        }
        
        return (false, "Update failed with unknown error", false)
    }
    
    func installedFormulas() async -> [BrewPackage] {
        let result = await commandService.runCommand("info --json=v2 --installed",
                                                     path: brewPath)
        var formulas: [BrewPackage] = []
        
        guard let output = result.output, !output.isEmpty else {
            if let error = result.error {
                print("Error fetching installed packages: \(error)")
            } else {
                print("No output from brew command")
            }
            return formulas
        }
        
        let decoder = JSONDecoder()
        do{
            let brewInfo = try decoder.decode(BrewInfoResponse.self,
                                              from: Data(output.utf8))
            for formulaInfo in brewInfo.formulae {
                if let name = formulaInfo.name,
                   let stableVersion = formulaInfo.versions.stable,
                   let homepage = formulaInfo.homepage,
                   let installedVersion = formulaInfo.installed.first?.version {
                    let formula = BrewPackage(
                        name: name,
                        token: nil,
                        version: installedVersion,
                        latestVersion: stableVersion,
                        homepage: homepage,
                        type: .formula
                    )
                    formulas.append(formula)
                }
                
            }
            
            for caskInfo in brewInfo.casks {
                if let token = caskInfo.token,
                   let name = caskInfo.name?.first ?? caskInfo.token,
                   let homepage = caskInfo.homepage,
                   let installedVersion = caskInfo.installed,
                   let version = caskInfo.version {
                    let cask = BrewPackage(
                        name: name,
                        token: token,
                        version: installedVersion,
                        latestVersion: version,
                        homepage: homepage,
                        type: .cask
                    )
                    formulas.append(cask)
                }
            }
        } catch {
            print("Error decoding BrewInfoResponse: \(error)")
        }
        
        return formulas
    }
    
    
    func updatePackage(name: String) async -> Bool {
        let result = await commandService.runCommand("upgrade \(name)", path: brewPath)
        
        if let output = result.output {
            // Check for successful update
            if output.contains("Upgraded") || output.contains("upgraded")
                || result.error == nil || result.error?.isEmpty == true {
                return true
            }
        }
        return false
    }
    
    func totalIntalledPackages(type: BrewPackageType) async -> Int {
        let result = await commandService
            .runCommand("list --\(type == .cask ? "cask" : "formula")", path: brewPath)
        var count = 0
        if let output = result.output {
            let lines = output.split(separator: "\n")
            count = lines.count
        }
        
        return count
    }
    
    func delete(package: BrewPackage) async -> Bool {
        let command = package.type == .cask ? "uninstall --cask \(package.name)" : "uninstall \(package.name)"
        let result = await commandService.runCommand(command, path: brewPath)
        
        if let output = result.output {
            if output.contains("Uninstalled") || output.contains("uninstalled")
                || result.error == nil || result.error?.isEmpty == true {
                return true
            }
        }
        
        return false
    }
    
    func upgradeAllPackages() async -> Bool {
        let result = await commandService.runCommand("upgrade", path: brewPath)
        
        if let output = result.output {
            
            if output.contains("Upgraded") || output.contains("upgraded")
                || result.error == nil || result.error?.isEmpty == true {
                return true
            }
        }
        return false
    }
}
