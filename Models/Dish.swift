//
//  Dish.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation
import SwiftUI // Added for Color

struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
    var bought: Bool = false
}

struct Category: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var color: String // Store color as string for persistence
    var createdAt: Date = Date()
    
    // Computed property to get SwiftUI Color
    var swiftUIColor: Color {
        switch color {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct Dish: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var videoURL: String
    var ingredients: [Ingredient]
    var imageName: String
    var thumbnailURL: String?
    var categoryID: UUID? // Optional category assignment
}
