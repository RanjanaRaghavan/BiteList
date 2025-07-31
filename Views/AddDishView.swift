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
    @State private var thumbnailURL: String?
    @State private var selectedCategoryID: UUID?
    
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
                    TextField("Paste any YouTube or Instagram video URL", text: $videoURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Text("The app will automatically extract ingredients from the video")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Section(header: Text("Video Description (Optional)")) {
                    TextEditor(text: $videoDescription)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Only needed if automatic extraction doesn't work")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if videoDescription.isEmpty {
                        Text("Example: \"The video shows tomatoes, onions, garlic, olive oil, and pasta being used to make a simple tomato sauce\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isAnalyzing ? "Extracting ingredients..." : "Extract Ingredients Automatically")
                        }
                    }
                    .disabled(videoURL.isEmpty || isAnalyzing)
                }
                
                Section(header: Text("Category (Optional)")) {
                    if viewModel.categories.isEmpty {
                        Text("No categories available. Create categories to organize your recipes.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryID) {
                            Text("No Category").tag(nil as UUID?)
                            ForEach(viewModel.categories) { category in
                                HStack {
                                    Circle()
                                        .fill(category.swiftUIColor)
                                        .frame(width: 12, height: 12)
                                    Text(category.name)
                                }
                                .tag(category.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
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
                Text("Ingredients extracted automatically from the video!")
            }
        }
    }
    
    private func analyzeVideo() {
        guard !videoURL.isEmpty else { return }
        
        isAnalyzing = true
        
        // Debug: Check API configuration
        print("🔧 Debug: OpenAI configured: \(ConfigurationService.shared.isOpenAIConfigured)")
        print("🔧 Debug: YouTube configured: \(ConfigurationService.shared.isYouTubeConfigured)")
        print("🔧 Debug: Video URL: \(videoURL)")
        print("🔧 Debug: User description: \(videoDescription.isEmpty ? "None" : videoDescription)")
        
        Task {
            do {
                // Extract ingredients
                let ingredients = try await contentExtractionService.extractIngredients(
                    from: videoURL,
                    userDescription: videoDescription.isEmpty ? nil : videoDescription
                )
                
                // Extract thumbnail if it's a YouTube video
                if videoURL.contains("youtube.com") || videoURL.contains("youtu.be") {
                    do {
                        if let videoID = contentExtractionService.youtubeService?.extractVideoID(from: videoURL) {
                            let thumbnail = try await contentExtractionService.youtubeService?.getVideoThumbnail(videoID: videoID)
                            await MainActor.run {
                                self.thumbnailURL = thumbnail
                            }
                        }
                    } catch {
                        print("⚠️ Could not extract thumbnail: \(error.localizedDescription)")
                    }
                }
                
                print("🔧 Debug: Extracted ingredients count: \(ingredients.count)")
                print("🔧 Debug: Ingredients: \(ingredients)")
                
                await MainActor.run {
                    if ingredients.isEmpty {
                        ingredientsText = "No ingredients found. Please add them manually."
                        print("🔧 Debug: No ingredients found, showing manual message")
                    } else {
                        ingredientsText = ingredients.joined(separator: "\n")
                        showingSuccess = true
                        print("🔧 Debug: Ingredients found, showing success")
                    }
                    isAnalyzing = false
                }
            } catch {
                print("🔧 Debug: Error occurred: \(error.localizedDescription)")
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
        let newDish = Dish(
            name: name, 
            videoURL: videoURL, 
            ingredients: ingredients, 
            imageName: "pasta", 
            thumbnailURL: thumbnailURL,
            categoryID: selectedCategoryID
        )
        viewModel.addDish(newDish)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddDishView(viewModel: DishViewModel())
}
