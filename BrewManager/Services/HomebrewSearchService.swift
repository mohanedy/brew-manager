//
//  HomebrewSearchService.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import Foundation
import FactoryKit

protocol HomebrewSearchService {
    func searchPackages(query: String) async -> [BrewPackage]
}

final class DefaultHomebrewSearchService: HomebrewSearchService {
    
    init() {}
    
    @Injected(\.brewService) private var brewService: HomebrewService
    @Injected(\.networkService) private var networkService: NetworkService
    
    let formulaeURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    let casksURL = URL(string: "https://formulae.brew.sh/api/cask.json")!
    
    var fullPackages: [BrewPackage] = []
    
    func searchPackages(query: String) async -> [BrewPackage] {
        do  {
            if fullPackages.isEmpty {
                fullPackages = try await withThrowingTaskGroup(of: [BrewPackage].self) { taskGroup in
                    let installedPackages = await brewService.installedFormulas()
                    taskGroup.addTask {
                        let formulaeData = try await self.networkService
                            .fetchData(from: self.formulaeURL)
                        let formulae = try JSONDecoder()
                            .decode([BrewFormulaInfo].self, from: formulaeData)
                        return await MainActor.run {
                            formulae.map {
                                var brewPackage = BrewPackage(fromFormula: $0)
                                if let installedPackage = installedPackages
                                    .first(where: { $0.name == brewPackage.name }) {
                                    brewPackage.version = installedPackage.version
                                }
                                
                                return brewPackage
                            }
                        }
                    }
                    taskGroup.addTask {
                        let casksData = try await self.networkService
                            .fetchData(from: self.casksURL)
                        let casks = try JSONDecoder()
                            .decode([BrewCaskInfo].self, from: casksData)
                        return await MainActor.run {
                            casks.map {
                                var brewPackage = BrewPackage(fromCask: $0)
                                if let installedPackage = installedPackages
                                    .first(where: { $0.token == brewPackage.token }) {
                                    brewPackage.version = installedPackage.version
                                }
                                return brewPackage
                            }
                        }
                    }
                    
                    return try await taskGroup.reduce(into: [BrewPackage]()) { partialResult, element in
                        partialResult.append(contentsOf: element)
                    }
                }
            }
            
            let lowercasedQuery = query.lowercased()
            let packages = fullPackages.filter { package in
                package.name.lowercased().contains(lowercasedQuery) ||
                (package.description?.lowercased().contains(lowercasedQuery) ?? false)
            }
            
            return packages
            
        } catch {
            print("Error fetching formulae: \(error)")
            return []
        }
    }
    
}
