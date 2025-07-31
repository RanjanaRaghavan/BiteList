//
//  ConfigurationService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()
    
    private init() {}
    
    // This service now uses EnvironmentService for secure API key management
    // The EnvironmentService can read from .env files and environment variables
    
    var openAIAPIKey: String {
        return EnvironmentService.shared.openAIAPIKey
    }
    
    var isOpenAIConfigured: Bool {
        return EnvironmentService.shared.isOpenAIConfigured
    }
    
    var youtubeAPIKey: String {
        return EnvironmentService.shared.youtubeAPIKey
    }
    
    var isYouTubeConfigured: Bool {
        return EnvironmentService.shared.isYouTubeConfigured
    }
    

} 