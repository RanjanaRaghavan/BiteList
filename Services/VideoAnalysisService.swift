//
//  VideoAnalysisService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class VideoAnalysisService: ObservableObject {
    private let openAIService: OpenAIService
    private let youtubeService: YouTubeService?
    
    init(openAIService: OpenAIService, youtubeService: YouTubeService? = nil) {
        self.openAIService = openAIService
        self.youtubeService = youtubeService
    }
    
    func analyzeVideoForIngredients(videoURL: String, userDescription: String? = nil) async throws -> [String] {
        print("🔧 Debug: Starting video analysis for URL: \(videoURL)")
        print("🔧 Debug: YouTube service available: \(youtubeService != nil)")
        print("🔧 Debug: User description: \(userDescription ?? "None")")
        
        // Step 1: If user provided description, use it directly
        if let description = userDescription, !description.isEmpty {
            print("🤖 USER INPUT: Using user-provided description with AI analysis...")
            let userIngredients = try await openAIService.analyzeVideoForIngredients(videoDescription: description)
            print("✅ SUCCESS: Found \(userIngredients.count) ingredients using AI ANALYSIS of user description")
            print("🤖 User Description AI Ingredients: \(userIngredients)")
            return userIngredients
        }
        
        // Step 2: Check if it's a YouTube video and try to extract description
        if let youtubeService = youtubeService, 
           (videoURL.contains("youtube.com") || videoURL.contains("youtu.be")) {
            print("🎥 Detected YouTube video, attempting to extract description...")
            
            do {
                // Extract video ID from URL
                guard let videoID = youtubeService.extractVideoID(from: videoURL) else {
                    print("❌ Could not extract video ID from URL")
                    throw VideoAnalysisError.invalidURL
                }
                
                print("📋 Extracting video description for ID: \(videoID)")
                let description = try await youtubeService.getVideoDescription(videoID: videoID)
                print("📝 YouTube description length: \(description.count) characters")
                print("📝 YouTube description preview: \(description.prefix(100))...")
                
                // Check if description is meaningful (not empty or just basic info)
                let meaningfulDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                let isDescriptionMeaningful = meaningfulDescription.count > 50 && 
                    !meaningfulDescription.lowercased().contains("subscribe") &&
                    !meaningfulDescription.lowercased().contains("like and comment")
                
                if !isDescriptionMeaningful {
                    print("⚠️ YouTube description is empty or not meaningful, trying to get video transcript...")
                    
                    do {
                        let transcript = try await youtubeService.getVideoTranscript(videoID: videoID)
                        print("📝 Found video transcript: \(transcript.prefix(200))...")
                        
                        if transcript.count > 50 {
                            print("🤖 TRANSCRIPT ANALYSIS: Using AI to analyze video transcript for ingredients...")
                            let transcriptIngredients = try await openAIService.analyzeVideoForIngredients(videoDescription: transcript)
                            print("✅ SUCCESS: Found \(transcriptIngredients.count) ingredients using AI TRANSCRIPT ANALYSIS")
                            print("🤖 Transcript Analysis Ingredients: \(transcriptIngredients)")
                            return transcriptIngredients
                        } else {
                            print("⚠️ Transcript too short, falling back to generic video analysis...")
                        }
                    } catch YouTubeServiceError.noTranscriptAvailable {
                        print("⚠️ No transcript available for this video")
                    } catch {
                        print("❌ Error getting transcript: \(error.localizedDescription)")
                    }
                    
                    // Fallback to generic video analysis if transcript fails
                    print("🤖 GENERIC VIDEO ANALYSIS: Using AI with generic prompt...")
                    let videoAnalysisIngredients = try await openAIService.analyzeVideoForIngredients(videoDescription: "Analyze this cooking video and extract the ingredients shown or mentioned in the video content")
                    print("✅ SUCCESS: Found \(videoAnalysisIngredients.count) ingredients using AI GENERIC VIDEO ANALYSIS")
                    print("🤖 Generic Video Analysis Ingredients: \(videoAnalysisIngredients)")
                    return videoAnalysisIngredients
                }
                
                // Step 3: Check if ingredients are mentioned in the description (pure code, no AI)
                print("🔍 Checking for ingredients in snippet.description using code parsing...")
                let ingredientsFromDescription = youtubeService.checkForIngredientsInDescription(description)
                
                if !ingredientsFromDescription.isEmpty {
                    print("✅ SUCCESS: Found \(ingredientsFromDescription.count) ingredients using PURE CODE PARSING (no AI used)")
                    print("📋 Ingredients found: \(ingredientsFromDescription)")
                    return ingredientsFromDescription
                }
                
                // Step 4: If no ingredients found in snippet.description, use AI to analyze the text
                print("🤖 FALLBACK: No ingredients found in snippet.description, using AI to analyze text...")
                print("📝 AI analyzing snippet.description: \(description.prefix(200))...")
                let aiIngredients = try await openAIService.extractIngredientsFromRecipe(description)
                print("✅ SUCCESS: Found \(aiIngredients.count) ingredients using AI ANALYSIS")
                print("🤖 AI Ingredients found: \(aiIngredients)")
                return aiIngredients
                
            } catch YouTubeServiceError.apiQuotaExceeded {
                print("⚠️ YouTube API quota exceeded, falling back to video analysis...")
            } catch {
                print("❌ YouTube API error: \(error.localizedDescription), falling back to video analysis...")
            }
        }
        
        // Step 5: Fallback to original video analysis method
        print("🤖 FINAL FALLBACK: No YouTube API available, using AI video analysis...")
        print("🔧 Debug: Using fallback video analysis")
        let videoContent = try await extractVideoContent(from: videoURL)
        print("🔧 Debug: Fallback video content: \(videoContent)")
        let fallbackIngredients = try await openAIService.analyzeVideoForIngredients(videoDescription: videoContent)
        print("✅ SUCCESS: Found \(fallbackIngredients.count) ingredients using AI VIDEO ANALYSIS (final fallback)")
        print("🤖 AI Video Analysis Ingredients: \(fallbackIngredients)")
        return fallbackIngredients
    }
    
    private func extractVideoContent(from url: String) async throws -> String {
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