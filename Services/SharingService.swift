//
//  SharingService.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation
import UIKit

class SharingService {
    static let shared = SharingService()
    
    private init() {}
    
    func createShoppingListMessage(for dish: Dish) -> String {
        // Get only unchecked ingredients (items to buy)
        let itemsToBuy = dish.ingredients.filter { !$0.bought }
        
        if itemsToBuy.isEmpty {
            return "Shopping list for \(dish.name):\n✅ All items purchased!"
        }
        
        var message = "Shopping list for \(dish.name):\n\n"
        
        for (index, ingredient) in itemsToBuy.enumerated() {
            let quantity = ingredient.quantity.isEmpty ? "" : " (\(ingredient.quantity))"
            message += "\(index + 1). \(ingredient.name)\(quantity)\n"
        }
        
        message += "\nTotal items to buy: \(itemsToBuy.count)"
        
        return message
    }
    
    func createShoppingListText(for dish: Dish) -> String {
        return createShoppingListMessage(for: dish)
    }
    
    func shareShoppingList(for dish: Dish, from viewController: UIViewController) {
        let message = createShoppingListMessage(for: dish)
        
        let activityViewController = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        // Exclude some activity types that don't make sense for text
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .markupAsPDF
        ]
        
        // Present the share sheet
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
} 