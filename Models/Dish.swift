//
//  Dish.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import Foundation

struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
    var bought: Bool = false
}

struct Dish: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var videoURL: String
    var ingredients: [Ingredient]
    var imageName: String
}
