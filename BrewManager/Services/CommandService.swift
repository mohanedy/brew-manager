//
//  CommandService.swift
//  BrewManager
//
//  Created by Mohaned Yossry on 11/10/2025.
//

import Foundation
import OSLog

typealias CommandResult = (output: String?, error: String?)

protocol CommandService {
    func runCommand(_ arguments: String, path: String) async -> CommandResult
    func runCommandWithStreaming(_ arguments: String, path: String, onOutput: @escaping (String) -> Void) async -> CommandResult
}

class DefaultCommandService: CommandService {
    
    let logger = Logger(subsystem: "com.izam.BrewManager", category: "CommandService")
    
    @discardableResult
    func runCommand(_ arguments: String, path: String) async -> CommandResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    return continuation.resume(returning: (output: nil, error: "Service deallocated"))
                }
                
                self.logger.debug("Running command: \(path) \(arguments)")
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
                    
                    self.logger.debug("Command output: \(output.prefix(500))")
                    continuation.resume(returning: (output: output.isEmpty ? nil : output, error: error.isEmpty ? nil : error))
                } catch {
                    self.logger.error("Failed to run command: \(error.localizedDescription)")
                    continuation.resume(returning: (output: nil, error: error.localizedDescription))
                }
            }
        }
    }
    
    @discardableResult
    func runCommandWithStreaming(_ arguments: String, path: String, onOutput: @escaping (String) -> Void) async -> CommandResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    return continuation.resume(returning: (output: nil, error: "Service deallocated"))
                }
                
                self.logger.debug("Running streaming command: \(path) \(arguments)")
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = arguments.split(separator: " ").map(String.init)
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                var fullOutput = ""
                var fullError = ""
                
                // Handle output streaming line by line
                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                        fullOutput += output
                        // Call the callback for each line
                        DispatchQueue.main.async {
                            onOutput(output)
                        }
                    }
                }
                
                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                        fullError += error
                    }
                }
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    // Clean up handlers
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    
                    self.logger.debug("Streaming command completed")
                    continuation.resume(returning: (
                        output: fullOutput.isEmpty ? nil : fullOutput,
                        error: fullError.isEmpty ? nil : fullError
                    ))
                } catch {
                    self.logger.error("Failed to run streaming command: \(error.localizedDescription)")
                    continuation.resume(returning: (output: nil, error: error.localizedDescription))
                }
            }
        }
    }
}
