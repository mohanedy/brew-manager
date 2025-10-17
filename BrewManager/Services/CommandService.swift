//
//  CommandService.swift
//  BrewManager
//
//  Created by Izam on 11/10/2025.
//

import Foundation
import OSLog

typealias CommandResult = (output: String?, error: String?)

protocol CommandService {
    func runCommand(_ arguments: String, path: String) async -> CommandResult
}

class DefaultCommandService: CommandService {
    
    let logger = Logger(subsystem: "com.izam.BrewManager", category: "CommandService")
    
    @discardableResult
    func runCommand(_ arguments: String, path: String) async -> CommandResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                
                // Split arguments by whitespace into separate components
                process.arguments = arguments.split(separator: " ").map(String.init)
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                // Read data asynchronously to prevent deadlock
                var outputData = Data()
                var errorData = Data()
                
                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    outputData.append(handle.availableData)
                }
                
                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    errorData.append(handle.availableData)
                }
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    // Read any remaining data
                    outputData.append(outputPipe.fileHandleForReading.readDataToEndOfFile())
                    errorData.append(errorPipe.fileHandleForReading.readDataToEndOfFile())
                    
                    // Clean up handlers
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    
                    continuation.resume(returning: (output: output.isEmpty ? nil : output, error: error.isEmpty ? nil : error))
                } catch {
                    continuation.resume(returning: (output: nil, error: error.localizedDescription))
                }
            }
        }
    }
}
