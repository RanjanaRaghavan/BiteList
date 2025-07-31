//
//  RecipeTile.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct RecipeTile: View {
    let dish: Dish
    var itemsLeft: Int {
        dish.ingredients.filter { !$0.bought }.count
    }
    var subtitle: String {
        "\(itemsLeft) item\(itemsLeft == 1 ? "" : "s") left to buy"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dish image - use thumbnail URL if available, otherwise fallback to local image
            if let thumbnailURL = dish.thumbnailURL, !thumbnailURL.isEmpty {
                AsyncImage(url: URL(string: thumbnailURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                } placeholder: {
                    Image(dish.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                }
            } else {
                Image(dish.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.07), radius: 4, x: 0, y: 2)
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

// Helper extension for rounding specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    RecipeTile(
        dish: Dish(
            name: "Pasta",
            videoURL: "https://youtube.com/shorts/pasta",
            ingredients: [
                Ingredient(name: "Tomatoes", quantity: "3", bought: false),
                Ingredient(name: "Onion", quantity: "1", bought: true),
                Ingredient(name: "Garlic", quantity: "2 cloves", bought: false)
            ],
            imageName: "pasta" // Use your asset name here
        )
    )
} 
