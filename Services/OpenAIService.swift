//
//  OpenAIService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyzeVideoForIngredients(videoDescription: String) async throws -> [String] {
        let prompt = """
        Analyze the following video description and extract ONLY the ingredients that are explicitly mentioned or shown in the video. 
        
        Video Description: \(videoDescription)
        
        Instructions:
        1. Only list ingredients that are clearly mentioned or visible in the video
        2. Do not hallucinate or add ingredients that aren't in the video
        3. Return ingredients as a simple list, one per line
        4. If no ingredients are mentioned, return "No ingredients found"
        5. Focus only on food ingredients, not cooking utensils or equipment
        
        Please provide the ingredients:
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant that extracts ingredients from cooking videos. Only mention ingredients that are explicitly shown or mentioned in the video content."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.1
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIServiceError.jsonSerializationError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Check your OpenAI API key")
                throw OpenAIServiceError.apiError(statusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        return try parseIngredientsFromResponse(responseString)
    }
    
    func extractIngredientsFromRecipe(_ recipeText: String) async throws -> [String] {
        let prompt = """
        Extract ONLY the ingredients from the following recipe text. Focus on food ingredients and ignore cooking instructions, steps, or equipment.
        
        Recipe Text: \(recipeText)
        
        Instructions:
        1. Only list food ingredients that are mentioned in the recipe
        2. Do not include cooking instructions, steps, or equipment
        3. Return ingredients as a simple list, one per line
        4. If no ingredients are mentioned, return "No ingredients found"
        5. Clean up ingredient names (remove measurements if they're not part of the ingredient name)
        
        Please provide the ingredients:
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant that extracts ingredients from recipe text. Only mention ingredients that are explicitly listed in the recipe."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.1
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIServiceError.jsonSerializationError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Check your OpenAI API key")
                throw OpenAIServiceError.apiError(statusCode: httpResponse.statusCode)
            }
            throw OpenAIServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        return try parseIngredientsFromResponse(responseString)
    }
    
    private func parseIngredientsFromResponse(_ response: String) throws -> [String] {
        // Parse the JSON response from OpenAI
        guard let data = response.data(using: .utf8) else {
            throw OpenAIServiceError.invalidResponse
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw OpenAIServiceError.invalidResponse
            }
            
            // Parse the content for ingredients
            let lines = content.components(separatedBy: .newlines)
            let ingredients = lines.compactMap { line -> String? in
                let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip empty lines, numbers, and common prefixes
                if cleaned.isEmpty || cleaned.matches(of: /^\d+\./).count > 0 {
                    return nil
                }
                // Remove common prefixes like "- ", "* ", "• "
                let withoutPrefix = cleaned.replacingOccurrences(of: #"^[-*•]\s*"#, with: "", options: .regularExpression)
                return withoutPrefix.isEmpty ? nil : withoutPrefix
            }
            
            // Filter out "No ingredients found" or similar messages
            let filteredIngredients = ingredients.filter { ingredient in
                !ingredient.lowercased().contains("no ingredients") &&
                !ingredient.lowercased().contains("ingredients found") &&
                !ingredient.lowercased().contains("please provide")
            }
            
            return filteredIngredients
        } catch {
            throw OpenAIServiceError.invalidResponse
        }
    }
}

enum OpenAIServiceError: Error, LocalizedError {
    case invalidURL
    case jsonSerializationError
    case invalidResponse
    case apiError(statusCode: Int)
    case noIngredientsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .jsonSerializationError:
            return "Failed to serialize request"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        case .noIngredientsFound:
            return "No ingredients found in the video"
        }
    }
} 
