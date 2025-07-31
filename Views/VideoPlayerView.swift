//
//  VideoPlayerView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI
import WebKit

struct VideoPlayerView: View {
    let videoURL: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if let videoID = extractVideoID(from: videoURL) {
                    YouTubePlayerView(videoID: videoID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Could not load video")
                            .font(.headline)
                        Text("The video URL format is not supported")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Recipe Video")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.allowsBackForwardNavigationGestures = false
        
        // Create embedded YouTube player HTML
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background: #000; }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe
                    src="https://www.youtube.com/embed/\(videoID)?autoplay=1&rel=0&modestbranding=1&playsinline=1"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
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

#Preview {
    VideoPlayerView(videoURL: "https://youtube.com/shorts/-7jV8IGbfIk?si=oO_VmOWmrbVrCZma")
} 