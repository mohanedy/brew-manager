//
//  NetworkManager.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 25/10/2025.
//

import Foundation

protocol NetworkService {
    func fetchData(from url: URL) async throws -> Data
}

final class DefaultNetworkService: NetworkService {
    func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
