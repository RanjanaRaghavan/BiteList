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
    
    @Published var categories: [Category] = [
        Category(name: "Breakfast", color: "orange"),
        Category(name: "Desserts", color: "pink"),
        Category(name: "Main Course", color: "blue")
    ]
    
    // MARK: - Dish Management
    func addDish(_ dish: Dish) {
        dishes.append(dish)
    }
    
    func deleteDish(_ dish: Dish) {
        dishes.removeAll { $0.id == dish.id }
    }
    
    func toggleIngredient(for dishID: UUID, ingredientID: UUID) {
        guard let dishIndex = dishes.firstIndex(where: { $0.id == dishID }),
              let ingIndex = dishes[dishIndex].ingredients.firstIndex(where: { $0.id == ingredientID }) else { return }
        dishes[dishIndex].ingredients[ingIndex].bought.toggle()
    }
    
    // MARK: - Category Management
    func addCategory(_ category: Category) {
        categories.append(category)
    }
    
    func deleteCategory(_ category: Category) {
        // Remove category from all dishes that have it
        for i in dishes.indices {
            if dishes[i].categoryID == category.id {
                dishes[i].categoryID = nil
            }
        }
        // Remove the category
        categories.removeAll { $0.id == category.id }
    }
    
    func updateDishCategory(dishID: UUID, categoryID: UUID?) {
        guard let dishIndex = dishes.firstIndex(where: { $0.id == dishID }) else { return }
        dishes[dishIndex].categoryID = categoryID
    }
    
    // MARK: - Helper Methods
    func dishesInCategory(_ category: Category) -> [Dish] {
        return dishes.filter { $0.categoryID == category.id }
    }
    
    func dishesWithoutCategory() -> [Dish] {
        return dishes.filter { $0.categoryID == nil }
    }
    
    func categoryForDish(_ dish: Dish) -> Category? {
        guard let categoryID = dish.categoryID else { return nil }
        return categories.first { $0.id == categoryID }
    }
}
