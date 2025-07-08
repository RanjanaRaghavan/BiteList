//
//  AddDishView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct AddDishView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DishViewModel
    
    @State private var name = ""
    @State private var videoURL = ""
    @State private var ingredientsText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dish Name")) {
                    TextField("e.g. Pasta", text: $name)
                }
                Section(header: Text("Video URL")) {
                    TextField("Paste Instagram Reel or YouTube Short URL", text: $videoURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section(header: Text("Ingredients (one per line)")) {
                    TextEditor(text: $ingredientsText)
                        .frame(height: 100)
                }
            }
            .navigationBarTitle("Add Dish", displayMode: .inline)
            .navigationBarItems(trailing: Button("Save") {
                let ingredients = ingredientsText
                    .split(separator: "\n")
                    .map { Ingredient(name: String($0), quantity: "", bought: false) }
                let newDish = Dish(name: name, videoURL: videoURL, ingredients: ingredients, imageName: "pasta")
                viewModel.addDish(newDish)
                presentationMode.wrappedValue.dismiss()
            }.disabled(name.isEmpty || videoURL.isEmpty || ingredientsText.isEmpty))
        }
    }
}

#Preview {
    AddDishView(viewModel: DishViewModel())
}
