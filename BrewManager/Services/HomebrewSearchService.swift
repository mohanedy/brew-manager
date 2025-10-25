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
    
    @Injected(\.commandService) private var commandService: CommandService
    @Injected(\.networkService) private var networkService: NetworkService
    
    let formulaeURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    let casksURL = URL(string: "https://formulae.brew.sh/api/cask.json")!
    
    var fullPackages: [BrewPackage] = []
    
    func searchPackages(query: String) async -> [BrewPackage] {
        do  {
            if fullPackages.isEmpty {
                fullPackages = try await withThrowingTaskGroup(of: [BrewPackage].self) { taskGroup in
                    taskGroup.addTask {
                        let formulaeData = try await self.networkService
                            .fetchData(from: self.formulaeURL)
                        let formulae = try JSONDecoder()
                            .decode([BrewFormulaInfo].self, from: formulaeData)
                        return await MainActor.run {
                            formulae.map { BrewPackage(fromFormula: $0) }
                        }
                    }
                    taskGroup.addTask {
                        let casksData = try await self.networkService
                            .fetchData(from: self.casksURL)
                        let casks = try JSONDecoder()
                            .decode([BrewCaskInfo].self, from: casksData)
                        return await MainActor.run {
                            casks.map { BrewPackage(fromCask: $0) }
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
