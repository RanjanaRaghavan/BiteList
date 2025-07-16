//
//  AddDishView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct AddDishView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DishViewModel
    
    @State private var name = ""
    @State private var videoURL = ""
    @State private var ingredientsText = ""
    @State private var videoDescription = ""
    @State private var isAnalyzing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var showingAPISetup = false
    
    // Initialize services (in production, these would be injected)
    private let contentExtractionService: ContentExtractionService
    
    init(viewModel: DishViewModel) {
        self.viewModel = viewModel
        let openAIService = OpenAIService(apiKey: ConfigurationService.shared.openAIAPIKey)
        self.contentExtractionService = ContentExtractionService(openAIService: openAIService)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dish Name")) {
                    TextField("e.g. Pasta", text: $name)
                }
                
                Section(header: Text("Video URL")) {
                    TextField("Paste Instagram Reel or YouTube Short URL", text: $videoURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Video Description (Optional)")) {
                    TextEditor(text: $videoDescription)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Describe the ingredients if caption/comment extraction doesn't work")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if videoDescription.isEmpty {
                        Text("Example: \"The video shows tomatoes, onions, garlic, olive oil, and pasta being used to make a simple tomato sauce\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        Button("Try Demo Description") {
                            videoDescription = DemoConfiguration.getRandomSampleDescription()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
                
                Section {
                    Button(action: analyzeVideo) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isAnalyzing ? "Analyzing..." : "Extract Ingredients")
                        }
                    }
                    .disabled(videoURL.isEmpty || isAnalyzing)
                }
                
                Section(header: Text("Ingredients")) {
                    TextEditor(text: $ingredientsText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .navigationBarTitle("Add Dish", displayMode: .inline)
            .navigationBarItems(trailing: Button("Save") {
                saveDish()
            }.disabled(name.isEmpty || videoURL.isEmpty || ingredientsText.isEmpty))
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") { }
            } message: {
                Text("Ingredients extracted from content successfully!")
            }
        }
    }
    
    private func analyzeVideo() {
        guard !videoURL.isEmpty else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                let ingredients = try await contentExtractionService.extractIngredients(
                    from: videoURL,
                    userDescription: videoDescription.isEmpty ? nil : videoDescription
                )
                
                await MainActor.run {
                    if ingredients.isEmpty {
                        ingredientsText = "No ingredients found. Please add them manually."
                    } else {
                        ingredientsText = ingredients.joined(separator: "\n")
                        showingSuccess = true
                    }
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func saveDish() {
        let ingredients = ingredientsText
            .split(separator: "\n")
            .map { Ingredient(name: String($0), quantity: "", bought: false) }
        let newDish = Dish(name: name, videoURL: videoURL, ingredients: ingredients, imageName: "pasta")
        viewModel.addDish(newDish)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddDishView(viewModel: DishViewModel())
}
