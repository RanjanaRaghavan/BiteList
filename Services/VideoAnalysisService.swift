//
//  VideoAnalysisService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class VideoAnalysisService: ObservableObject {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func extractVideoContent(from url: String) async throws -> String {
        // For now, we'll return a placeholder since direct video content extraction
        // from Instagram/YouTube requires additional services or manual input
        // In a production app, you might integrate with:
        // - YouTube Data API for YouTube videos
        // - Instagram Basic Display API (with limitations)
        // - Third-party services that can extract video transcripts
        
        if url.contains("youtube.com") || url.contains("youtu.be") {
            return "YouTube video content would be extracted here. For now, please provide a description of the ingredients shown in the video."
        } else if url.contains("instagram.com") {
            return "Instagram video content would be extracted here. For now, please provide a description of the ingredients shown in the video."
        } else {
            return "Please provide a description of the ingredients shown in the video."
        }
    }
    
    func analyzeVideoForIngredients(videoURL: String, userDescription: String? = nil) async throws -> [String] {
        var videoContent = ""
        
        if let description = userDescription, !description.isEmpty {
            videoContent = description
        } else {
            videoContent = try await extractVideoContent(from: videoURL)
        }
        
        return try await openAIService.analyzeVideoForIngredients(videoDescription: videoContent)
    }
}

enum VideoAnalysisError: Error, LocalizedError {
    case unsupportedPlatform
    case invalidURL
    case noContentAvailable
    
    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            return "This video platform is not supported"
        case .invalidURL:
            return "Invalid video URL"
        case .noContentAvailable:
            return "No video content available for analysis"
        }
    }
} 