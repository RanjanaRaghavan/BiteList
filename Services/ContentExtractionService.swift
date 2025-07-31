//
//  ContentExtractionService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class ContentExtractionService: ObservableObject {
    private let openAIService: OpenAIService
    private let videoAnalysisService: VideoAnalysisService
    let youtubeService: YouTubeService?
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
        
        // Initialize YouTube service if API key is available
        if ConfigurationService.shared.isYouTubeConfigured {
            print("🔧 Debug: YouTube API configured, creating YouTube service")
            self.youtubeService = YouTubeService(apiKey: ConfigurationService.shared.youtubeAPIKey)
        } else {
            print("🔧 Debug: YouTube API not configured, YouTube service will be nil")
            self.youtubeService = nil
        }
        
        self.videoAnalysisService = VideoAnalysisService(openAIService: openAIService, youtubeService: youtubeService)
    }
    
    func extractIngredients(from url: String, userDescription: String? = nil) async throws -> [String] {
        // Hierarchy: 1. YouTube API direct ingredients 2. OpenAI recipe analysis 3. Video analysis fallback
        print("🔄 Starting ingredient extraction process...")
        print("🔧 Debug: URL: \(url)")
        print("🔧 Debug: User description provided: \(userDescription != nil)")
        print("🔧 Debug: YouTube service available: \(youtubeService != nil)")
        
        let result = try await analyzeVideoDescription(url: url, userDescription: userDescription)
        print("🔧 Debug: Final result count: \(result.count)")
        return result
    }
    

    
    private func analyzeVideoDescription(url: String, userDescription: String?) async throws -> [String] {
        // Use the enhanced video analysis service
        return try await videoAnalysisService.analyzeVideoForIngredients(videoURL: url, userDescription: userDescription)
    }
    

}

enum ContentExtractionError: Error, LocalizedError {
    case noContentFound
    case parsingError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noContentFound:
            return "No content found to extract ingredients from"
        case .parsingError:
            return "Error parsing content"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
} 