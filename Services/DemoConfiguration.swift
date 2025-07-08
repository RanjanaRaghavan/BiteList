//
//  DemoConfiguration.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

struct DemoConfiguration {
    static let sampleVideoDescriptions = [
        "The video shows a chef making pasta carbonara with eggs, pancetta, parmesan cheese, black pepper, and spaghetti. The ingredients are clearly visible as they're added to the pan.",
        
        "This cooking video demonstrates making a simple tomato sauce using fresh tomatoes, onions, garlic, olive oil, basil leaves, salt, and pepper. All ingredients are shown being chopped and added to the pot.",
        
        "The video features making chicken curry with chicken breast, onions, tomatoes, ginger, garlic, turmeric powder, cumin seeds, coriander powder, and coconut milk. Each ingredient is measured and added step by step.",
        
        "This recipe video shows baking chocolate chip cookies with flour, butter, sugar, eggs, vanilla extract, chocolate chips, baking soda, and salt. The ingredients are clearly displayed on the counter before mixing.",
        
        "The video demonstrates making a healthy smoothie bowl with frozen bananas, strawberries, almond milk, chia seeds, granola, and fresh berries for topping. All ingredients are shown being blended and arranged."
    ]
    
    static func getRandomSampleDescription() -> String {
        return sampleVideoDescriptions.randomElement() ?? sampleVideoDescriptions[0]
    }
} 