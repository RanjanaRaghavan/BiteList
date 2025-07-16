//
//  ContentExtractionService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class ContentExtractionService: ObservableObject {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func extractIngredients(from url: String, userDescription: String? = nil) async throws -> [String] {
        // Hierarchy: 1. Caption 2. Pinned Comment 3. Video Analysis
        
        // Step 1: Try to extract from caption
        if let captionIngredients = try await extractFromCaption(url: url) {
            print("✅ Found ingredients in caption")
            return captionIngredients
        }
        
        // Step 2: Try to extract from pinned comment
        if let commentIngredients = try await extractFromPinnedComment(url: url) {
            print("✅ Found ingredients in pinned comment")
            return commentIngredients
        }
        
        // Step 3: Fallback to video analysis (existing functionality)
        print("🔄 No structured content found, analyzing video description")
        return try await analyzeVideoDescription(url: url, userDescription: userDescription)
    }
    
    private func extractFromCaption(url: String) async throws -> [String]? {
        // For now, this is a placeholder since we can't directly access social media APIs
        // In a production app, you would integrate with:
        // - Instagram Basic Display API
        // - YouTube Data API
        // - Third-party services that can extract captions
        
        // For demo purposes, we'll simulate finding structured content
        // In reality, this would make API calls to get the actual caption
        
        if url.contains("instagram.com") {
            // Simulate Instagram caption extraction
            return try await simulateCaptionExtraction(platform: "Instagram")
        } else if url.contains("youtube.com") || url.contains("youtu.be") {
            // Simulate YouTube description extraction
            return try await simulateCaptionExtraction(platform: "YouTube")
        }
        
        return nil
    }
    
    private func extractFromPinnedComment(url: String) async throws -> [String]? {
        // Similar to caption extraction, but for pinned comments
        // This would require API access to comments
        
        if url.contains("instagram.com") {
            return try await simulatePinnedCommentExtraction(platform: "Instagram")
        } else if url.contains("youtube.com") || url.contains("youtu.be") {
            return try await simulatePinnedCommentExtraction(platform: "YouTube")
        }
        
        return nil
    }
    
    private func analyzeVideoDescription(url: String, userDescription: String?) async throws -> [String] {
        // This is the existing video analysis functionality
        var videoContent = ""
        
        if let description = userDescription, !description.isEmpty {
            videoContent = description
        } else {
            videoContent = try await extractVideoContent(from: url)
        }
        
        return try await openAIService.analyzeVideoForIngredients(videoDescription: videoContent)
    }
    
    private func extractVideoContent(from url: String) async throws -> String {
        // Existing video content extraction logic
        if url.contains("youtube.com") || url.contains("youtu.be") {
            return "YouTube video content would be extracted here. For now, please provide a description of the ingredients shown in the video."
        } else if url.contains("instagram.com") {
            return "Instagram video content would be extracted here. For now, please provide a description of the ingredients shown in the video."
        } else {
            return "Please provide a description of the ingredients shown in the video."
        }
    }
    
    // MARK: - Demo/Simulation Methods
    
    private func simulateCaptionExtraction(platform: String) async throws -> [String]? {
        // Simulate finding structured ingredient lists in captions
        // In reality, this would parse actual caption text
        
        let structuredCaptions = [
            "Ingredients:\n- 2 cups flour\n- 1 cup sugar\n- 3 eggs\n- 1/2 cup milk",
            "INGREDIENTS:\n• Tomatoes\n• Onions\n• Garlic\n• Olive oil",
            "What you need:\n1. Chicken breast\n2. Rice\n3. Vegetables\n4. Spices"
        ]
        
        // Simulate 30% chance of finding structured content
        if Int.random(in: 1...10) <= 3 {
            let randomCaption = structuredCaptions.randomElement()!
            return parseStructuredIngredients(from: randomCaption)
        }
        
        return nil
    }
    
    private func simulatePinnedCommentExtraction(platform: String) async throws -> [String]? {
        // Simulate finding ingredient lists in pinned comments
        // In reality, this would parse actual pinned comment text
        
        let pinnedComments = [
            "Ingredients list:\n- Pasta\n- Tomatoes\n- Basil\n- Parmesan",
            "RECIPE INGREDIENTS:\n• Flour\n• Butter\n• Sugar\n• Vanilla",
            "Here's what you need:\n1. Eggs\n2. Milk\n3. Bread\n4. Cheese"
        ]
        
        // Simulate 20% chance of finding structured content in pinned comments
        if Int.random(in: 1...10) <= 2 {
            let randomComment = pinnedComments.randomElement()!
            return parseStructuredIngredients(from: randomComment)
        }
        
        return nil
    }
    
    private func parseStructuredIngredients(from text: String) -> [String] {
        // Parse structured ingredient lists (bullet points, numbered lists, etc.)
        let lines = text.components(separatedBy: .newlines)
        var ingredients: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and headers
            if trimmed.isEmpty || 
               trimmed.lowercased().contains("ingredients") ||
               trimmed.lowercased().contains("what you need") {
                continue
            }
            
            // Remove bullet points, numbers, and dashes
            let cleaned = trimmed
                .replacingOccurrences(of: #"^[-•*]\s*"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleaned.isEmpty {
                ingredients.append(cleaned)
            }
        }
        
        return ingredients
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