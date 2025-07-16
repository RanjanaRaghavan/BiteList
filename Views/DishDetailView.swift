//
//  DishDetailView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct DishDetailView: View {
    @ObservedObject var viewModel: DishViewModel
    let dish: Dish
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dish.name)
                .font(.largeTitle)
                .bold()
            
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
            
            Spacer()
            
            if let url = URL(string: dish.videoURL) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("Watch Recipe Video")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [SharingService.shared.createShoppingListText(for: dish)])
        }
    }
}

#Preview {
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
    return DishDetailView(viewModel: DishViewModel(), dish: sampleDish)
}
