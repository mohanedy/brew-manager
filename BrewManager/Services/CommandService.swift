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
    
    // Actor for thread-safe output accumulation
    private actor OutputAccumulator {
        var output = ""
        var error = ""
        
        func appendOutput(_ text: String) {
            output += text
        }
        
        func appendError(_ text: String) {
            error += text
        }
        
        func getResults() -> (output: String, error: String) {
            return (output, error)
        }
    }
    
    @discardableResult
    func runCommand(_ arguments: String, path: String) async -> CommandResult {
        logger.debug("Running command: \(path) \(arguments)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        
        // Split arguments by whitespace into separate components
        process.arguments = arguments.split(separator: " ").map(String.init)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // Use async sequences to read data concurrently
            async let outputData = readData(from: outputPipe.fileHandleForReading)
            async let errorData = readData(from: errorPipe.fileHandleForReading)
            
            // Wait for process to complete on a background task
            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
            
            let output = String(data: try await outputData, encoding: .utf8) ?? ""
            let error = String(data: try await errorData, encoding: .utf8) ?? ""
            
            logger.debug("Command output: \(output.prefix(500))")
            return (output: output.isEmpty ? nil : output, error: error.isEmpty ? nil : error)
        } catch {
            logger.error("Failed to run command: \(error.localizedDescription)")
            return (output: nil, error: error.localizedDescription)
        }
    }
    
    private func readData(from fileHandle: FileHandle) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                var accumulatedData = Data()
                
                let notificationCenter = NotificationCenter.default
                let observer = notificationCenter.addObserver(
                    forName: .NSFileHandleDataAvailable,
                    object: fileHandle,
                    queue: nil
                ) { _ in
                    let data = fileHandle.availableData
                    if !data.isEmpty {
                        accumulatedData.append(data)
                        fileHandle.waitForDataInBackgroundAndNotify()
                    }
                }
                
                fileHandle.waitForDataInBackgroundAndNotify()
                
                // Use Task.sleep instead of Thread.sleep for better async handling
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                notificationCenter.removeObserver(observer)
                
                // Read any remaining data
                let remainingData = try? fileHandle.readToEnd() ?? Data()
                if let remainingData = remainingData {
                    accumulatedData.append(remainingData)
                }
                
                continuation.resume(returning: accumulatedData)
            }
        }
    }
    
    @discardableResult
    func runCommandWithStreaming(_ arguments: String, path: String, onOutput: @escaping (String) -> Void) async -> CommandResult {
        logger.debug("Running streaming command: \(path) \(arguments)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments.split(separator: " ").map(String.init)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Use actor for thread-safe accumulation
        let accumulator = OutputAccumulator()
        
        // Handle output streaming line by line
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                Task {
                    await accumulator.appendOutput(output)
                    
                    // Call the callback on the main actor
                    await MainActor.run {
                        onOutput(output)
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                Task {
                    await accumulator.appendError(error)
                }
            }
        }
        
        do {
            try process.run()
            
            // Wait for process to complete
            await withCheckedContinuation { continuation in
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
            
            // Clean up handlers
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            logger.debug("Streaming command completed")
            
            // Safely read final values from actor
            let results = await accumulator.getResults()
            
            return (
                output: results.output.isEmpty ? nil : results.output,
                error: results.error.isEmpty ? nil : results.error
            )
        } catch {
            logger.error("Failed to run streaming command: \(error.localizedDescription)")
            return (output: nil, error: error.localizedDescription)
        }
    }
}
