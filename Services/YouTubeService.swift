//
//  YouTubeService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class YouTubeService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func extractVideoID(from url: String) -> String? {
        // Handle different YouTube URL formats
        let patterns = [
            #"youtube\.com/watch\?v=([a-zA-Z0-9_-]+)"#,
            #"youtu\.be/([a-zA-Z0-9_-]+)"#,
            #"youtube\.com/embed/([a-zA-Z0-9_-]+)"#,
            #"youtube\.com/v/([a-zA-Z0-9_-]+)"#,
            #"youtube\.com/shorts/([a-zA-Z0-9_-]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) {
                let videoIDRange = match.range(at: 1)
                if let range = Range(videoIDRange, in: url) {
                    return String(url[range])
                }
            }
        }
        return nil
    }
    
    func getVideoDescription(videoID: String) async throws -> String {
        let endpoint = "\(baseURL)/videos"
        var components = URLComponents(string: endpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "id", value: videoID),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw YouTubeServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw YouTubeServiceError.apiQuotaExceeded
            }
            throw YouTubeServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        return try parseVideoDescription(from: data)
    }
    
    func getVideoTranscript(videoID: String) async throws -> String {
        // First, get the caption tracks for the video
        let captionsEndpoint = "\(baseURL)/captions"
        var components = URLComponents(string: captionsEndpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "videoId", value: videoID),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw YouTubeServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw YouTubeServiceError.apiQuotaExceeded
            }
            throw YouTubeServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse caption tracks and get the first available transcript
        let captionTracks = try parseCaptionTracks(from: data)
        
        if let firstCaptionTrack = captionTracks.first {
            print("📝 Found caption track: \(firstCaptionTrack.language) - \(firstCaptionTrack.name)")
            return try await downloadTranscript(captionID: firstCaptionTrack.id)
        } else {
            print("⚠️ No caption tracks found for video")
            throw YouTubeServiceError.noTranscriptAvailable
        }
    }
    
    private func parseCaptionTracks(from data: Data) throws -> [CaptionTrack] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw YouTubeServiceError.invalidResponse
        }
        
        var captionTracks: [CaptionTrack] = []
        
        for item in items {
            if let snippet = item["snippet"] as? [String: Any],
               let id = snippet["id"] as? String,
               let language = snippet["language"] as? String,
               let name = snippet["name"] as? String {
                
                captionTracks.append(CaptionTrack(
                    id: id,
                    language: language,
                    name: name
                ))
            }
        }
        
        return captionTracks
    }
    
    private func downloadTranscript(captionID: String) async throws -> String {
        let transcriptEndpoint = "\(baseURL)/captions/\(captionID)"
        var components = URLComponents(string: transcriptEndpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw YouTubeServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw YouTubeServiceError.apiQuotaExceeded
            }
            throw YouTubeServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse the transcript XML and extract text
        return try parseTranscriptXML(from: data)
    }
    
    private func parseTranscriptXML(from data: Data) throws -> String {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw YouTubeServiceError.invalidResponse
        }
        
        // Simple XML parsing to extract text from <text> tags
        let textPattern = #"<text[^>]*>(.*?)</text>"#
        let regex = try NSRegularExpression(pattern: textPattern, options: [.dotMatchesLineSeparators])
        
        let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
        
        var transcriptText = ""
        for match in matches {
            if let range = Range(match.range(at: 1), in: xmlString) {
                let text = String(xmlString[range])
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&#39;", with: "'")
                
                transcriptText += text + " "
            }
        }
        
        return transcriptText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseVideoDescription(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let firstItem = items.first,
              let snippet = firstItem["snippet"] as? [String: Any],
              let description = snippet["description"] as? String else {
            throw YouTubeServiceError.invalidResponse
        }
        
        return description
    }
    
    func getVideoThumbnail(videoID: String) async throws -> String {
        let endpoint = "\(baseURL)/videos"
        var components = URLComponents(string: endpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "id", value: videoID),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw YouTubeServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw YouTubeServiceError.apiQuotaExceeded
            }
            throw YouTubeServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        return try parseVideoThumbnail(from: data)
    }
    
    private func parseVideoThumbnail(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let firstItem = items.first,
              let snippet = firstItem["snippet"] as? [String: Any],
              let thumbnails = snippet["thumbnails"] as? [String: Any] else {
            throw YouTubeServiceError.invalidResponse
        }
        
        // Try to get the highest quality thumbnail available
        // Priority: maxres > high > medium > standard > default
        let thumbnailKeys = ["maxres", "high", "medium", "standard", "default"]
        
        for key in thumbnailKeys {
            if let thumbnail = thumbnails[key] as? [String: Any],
               let url = thumbnail["url"] as? String {
                print("📸 Found thumbnail: \(key) - \(url)")
                return url
            }
        }
        
        throw YouTubeServiceError.noThumbnailAvailable
    }
    
    func checkForIngredientsInDescription(_ description: String) -> [String] {
        // Common ingredient keywords to look for
        let ingredientKeywords = [
            "ingredients:", "ingredient:", "what you'll need:", "you'll need:",
            "ingredients list:", "ingredient list:", "what you need:", "needed:",
            "ingredients required:", "required ingredients:", "ingredients for:"
        ]
        
        let lines = description.components(separatedBy: .newlines)
        var ingredients: [String] = []
        var foundIngredientsSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line starts an ingredients section
            if !foundIngredientsSection {
                for keyword in ingredientKeywords {
                    if trimmedLine.lowercased().contains(keyword.lowercased()) {
                        foundIngredientsSection = true
                        break
                    }
                }
            }
            
            // If we're in an ingredients section, collect ingredients
            if foundIngredientsSection && !trimmedLine.isEmpty {
                // Skip lines that are likely not ingredients
                if trimmedLine.lowercased().contains("instructions") ||
                   trimmedLine.lowercased().contains("directions") ||
                   trimmedLine.lowercased().contains("method") ||
                   trimmedLine.lowercased().contains("steps") {
                    break
                }
                
                // Clean up the ingredient line
                let cleanedIngredient = cleanIngredientLine(trimmedLine)
                if !cleanedIngredient.isEmpty {
                    ingredients.append(cleanedIngredient)
                }
            }
        }
        
        return ingredients
    }
    
    private func cleanIngredientLine(_ line: String) -> String {
        // Remove common prefixes and clean up the ingredient
        var cleaned = line
        
        // Remove bullet points, numbers, and common prefixes
        cleaned = cleaned.replacingOccurrences(of: #"^[-*•]\s*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"^\d+\)\s*"#, with: "", options: .regularExpression)
        
        // Remove common measurement prefixes that might be at the start
        let measurementPatterns = [
            #"^\d+\s*(cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|oz|ounce|ounces|g|gram|grams|kg|kilogram|kilograms|ml|milliliter|milliliters|l|liter|liters|lb|pound|pounds)\s*"#,
            #"^\d+\/\d+\s*(cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|oz|ounce|ounces|g|gram|grams|kg|kilogram|kilograms|ml|milliliter|milliliters|l|liter|liters|lb|pound|pounds)\s*"#
        ]
        
        for pattern in measurementPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CaptionTrack {
    let id: String
    let language: String
    let name: String
}

enum YouTubeServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case apiQuotaExceeded
    case videoNotFound
    case invalidVideoID
    case noTranscriptAvailable
    case noThumbnailAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid YouTube URL"
        case .invalidResponse:
            return "Invalid response from YouTube API"
        case .apiError(let statusCode):
            return "YouTube API error with status code: \(statusCode)"
        case .apiQuotaExceeded:
            return "YouTube API quota exceeded"
        case .videoNotFound:
            return "Video not found"
        case .invalidVideoID:
            return "Invalid video ID"
        case .noTranscriptAvailable:
            return "No transcript available for this video"
        case .noThumbnailAvailable:
            return "No thumbnail available for this video"
        }
    }
} 