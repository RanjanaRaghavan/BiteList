//
//  DishDetailView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI
import WebKit

struct DishDetailView: View {
    @ObservedObject var viewModel: DishViewModel
    let dish: Dish
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe title with proper spacing
                VStack(alignment: .leading, spacing: 8) {
                    Text(dish.name)
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 8)
                
                HStack {
                    Text("Shopping List")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share List")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                
                ForEach(dish.ingredients) { ingredient in
                    HStack {
                        Button(action: {
                            viewModel.toggleIngredient(for: dish.id, ingredientID: ingredient.id)
                        }) {
                            Image(systemName: ingredient.bought ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(ingredient.bought ? .green : .gray)
                        }
                        Text(ingredient.name)
                        Spacer()
                        if !ingredient.quantity.isEmpty {
                            Text(ingredient.quantity)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Embedded YouTube Video
                if let videoID = extractVideoID(from: dish.videoURL) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipe Video")
                            .font(.headline)
                            .padding(.top, 16)
                        
                        EmbeddedYouTubePlayer(videoID: videoID)
                            .frame(height: 220)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                } else if !dish.videoURL.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Video not available")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Bottom padding for scroll view
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [SharingService.shared.createShoppingListText(for: dish)])
        }
        // Removed VideoPlayerView sheet since we're using embedded player
    }
    
    private func extractVideoID(from url: String) -> String? {
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
}

struct EmbeddedYouTubePlayer: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        // Configure web view for inline video playback
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false
        webView.backgroundColor = UIColor.black
        
        // Create embedded YouTube player HTML for inline display
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    margin: 0; 
                    padding: 0; 
                    background: #000; 
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                    border-radius: 8px;
                    pointer-events: auto;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe
                    src="https://www.youtube.com/embed/\(videoID)?rel=0&modestbranding=1&playsinline=1&controls=1&enablejsapi=1&origin=\(Bundle.main.bundleIdentifier ?? "")"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen
                    webkit-playsinline>
                </iframe>
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

struct DishDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDish = Dish(
            name: "Pasta",
            videoURL: "https://youtube.com/shorts/pasta",
            ingredients: [
                Ingredient(name: "Tomatoes", quantity: "3", bought: false),
                Ingredient(name: "Onion", quantity: "1", bought: true),
                Ingredient(name: "Garlic", quantity: "2 cloves", bought: false)
            ],
            imageName: "pasta"
        )
        DishDetailView(viewModel: DishViewModel(), dish: sampleDish)
    }
}
