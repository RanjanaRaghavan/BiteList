//
//  EnvironmentService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class EnvironmentService {
    static let shared = EnvironmentService()
    
    private var environmentVariables: [String: String] = [:]
    
    private init() {
        loadEnvironmentFile()
    }
    
    private func loadEnvironmentFile() {
        // 1. Try to load from current working directory (project root)
        let cwdEnvPath = FileManager.default.currentDirectoryPath + "/.env"
        print("🔍 Checking for .env in CWD: \(cwdEnvPath)")
        if FileManager.default.fileExists(atPath: cwdEnvPath) {
            print("✅ Found .env in CWD")
            loadFromFile(path: cwdEnvPath)
        }
        // 2. Try to load from .env file in app bundle (not recommended, but kept for completeness)
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            print("🔍 Checking for .env in Bundle: \(envPath)")
            loadFromFile(path: envPath)
        }
        // 3. Try to load from .env file in the app's documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let envFileURL = documentsPath.appendingPathComponent(".env")
            print("🔍 Checking for .env in Documents: \(envFileURL.path)")
            if FileManager.default.fileExists(atPath: envFileURL.path) {
                print("✅ Found .env in Documents")
                loadFromFile(path: envFileURL.path)
            }
        }
    }
    
    private func loadFromFile(path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse key=value format
                if let range = trimmedLine.range(of: "=") {
                    let key = String(trimmedLine[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(trimmedLine[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Remove quotes if present
                    let cleanValue = value.replacingOccurrences(of: "\"", with: "")
                    
                    environmentVariables[key] = cleanValue
                }
            }
        } catch {
            print("Error loading .env file: \(error)")
        }
    }
    
    func getValue(for key: String) -> String? {
        // First check environment variables (for Xcode scheme configuration)
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        
        // Then check .env file
        return environmentVariables[key]
    }
    
    func getValue(for key: String, defaultValue: String) -> String {
        return getValue(for: key) ?? defaultValue
    }
    
    // Convenience method for OpenAI API key
    var openAIAPIKey: String {
        let key = getValue(for: "OPENAI_API_KEY", defaultValue: "your-openai-api-key-here")
        print("🔑 OpenAI API Key loaded: \(key.prefix(10))...") // Only show first 10 chars for security
        return key
    }
    
    var isOpenAIConfigured: Bool {
        let key = openAIAPIKey
        return key != "your-openai-api-key-here" && !key.isEmpty
    }
    
    // Convenience method for YouTube API key
    var youtubeAPIKey: String {
        let key = getValue(for: "YOUTUBE_API_KEY", defaultValue: "your-youtube-api-key-here")
        print("🔑 YouTube API Key loaded: \(key.prefix(10))...") // Only show first 10 chars for security
        return key
    }
    
    var isYouTubeConfigured: Bool {
        let key = youtubeAPIKey
        return key != "your-youtube-api-key-here" && !key.isEmpty
    }
    

} 
