//
//  DishViewModel.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

import SwiftUI

class DishViewModel: ObservableObject {
    @Published var dishes: [Dish] = [
        Dish(
            name: "Samosa",
            videoURL: "https://www.instagram.com/reel/samosa",
            ingredients: [
                Ingredient(name: "Potato", quantity: "2", bought: false),
                Ingredient(name: "Peas", quantity: "1 cup", bought: false),
                Ingredient(name: "Flour", quantity: "200g", bought: true)
            ],
            imageName: "samosa"
        ),
        Dish(
            name: "Pasta",
            videoURL: "https://www.youtube.com/shorts/pasta",
            ingredients: [
                Ingredient(name: "Tomatoes", quantity: "3", bought: false),
                Ingredient(name: "Onion", quantity: "1", bought: true),
                Ingredient(name: "Garlic", quantity: "2 cloves", bought: false)
            ],
            imageName: "pasta"
        )
    ]
    
    func addDish(_ dish: Dish) {
        dishes.append(dish)
    }
    
    func toggleIngredient(for dishID: UUID, ingredientID: UUID) {
        guard let dishIndex = dishes.firstIndex(where: { $0.id == dishID }),
              let ingIndex = dishes[dishIndex].ingredients.firstIndex(where: { $0.id == ingredientID }) else { return }
        dishes[dishIndex].ingredients[ingIndex].bought.toggle()
    }
}
