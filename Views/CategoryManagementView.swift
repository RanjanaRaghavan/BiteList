//
//  CategoryManagementView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var viewModel: DishViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Categories Section
                Section("Categories") {
                    ForEach(viewModel.categories) { category in
                        CategoryRowView(category: category, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteCategories)
                }
                
                // Uncategorized Dishes Section
                Section("Uncategorized Dishes") {
                    let uncategorizedDishes = viewModel.dishesWithoutCategory()
                    if uncategorizedDishes.isEmpty {
                        Text("All dishes are categorized")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(uncategorizedDishes) { dish in
                            DishCategoryRowView(dish: dish, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = viewModel.categories[index]
            viewModel.deleteCategory(category)
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    @ObservedObject var viewModel: DishViewModel
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.swiftUIColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading) {
                Text(category.name)
                    .font(.headline)
                Text("\(viewModel.dishesInCategory(category).count) dishes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            NavigationLink(destination: CategoryDetailView(category: category, viewModel: viewModel)) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct DishCategoryRowView: View {
    let dish: Dish
    @ObservedObject var viewModel: DishViewModel
    @State private var showingCategoryPicker = false
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: dish.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(dish.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(dish.name)
                    .font(.headline)
                if let category = viewModel.categoryForDish(dish) {
                    HStack {
                        Circle()
                            .fill(category.swiftUIColor)
                            .frame(width: 12, height: 12)
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                showingCategoryPicker = true
            }) {
                Image(systemName: "folder.badge.plus")
                    .foregroundColor(.blue)
            }
        }
        .actionSheet(isPresented: $showingCategoryPicker) {
            ActionSheet(
                title: Text("Move to Category"),
                message: Text("Select a category for '\(dish.name)'"),
                buttons: createActionSheetButtons()
            )
        }
    }
    
    private func createActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add category options
        for category in viewModel.categories {
            buttons.append(.default(Text(category.name)) {
                viewModel.updateDishCategory(dishID: dish.id, categoryID: category.id)
            })
        }
        
        // Add "Remove from category" option if dish is categorized
        if viewModel.categoryForDish(dish) != nil {
            buttons.append(.destructive(Text("Remove from category")) {
                viewModel.updateDishCategory(dishID: dish.id, categoryID: nil)
            })
        }
        
        buttons.append(.cancel())
        return buttons
    }
}

struct CategoryDetailView: View {
    let category: Category
    @ObservedObject var viewModel: DishViewModel
    @State private var showDishActionSheet = false
    @State private var selectedDish: Dish?
    
    var body: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .fill(category.swiftUIColor)
                        .frame(width: 30, height: 30)
                    Text(category.name)
                        .font(.title2)
                        .bold()
                    Spacer()
                }
            }
            
            Section("Dishes in this category") {
                let dishesInCategory = viewModel.dishesInCategory(category)
                if dishesInCategory.isEmpty {
                    Text("No dishes in this category")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(dishesInCategory) { dish in
                        NavigationLink(destination: DishDetailView(viewModel: viewModel, dish: dish)) {
                            RecipeTile(dish: dish)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        print("🔧 Dish long-press detected in category for: \(dish.name)")
                                        showDishActionSheet(for: dish)
                                    }
                                }
                        )
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .actionSheet(isPresented: $showDishActionSheet) {
            ActionSheet(
                title: Text("Recipe Options"),
                message: Text("What would you like to do with '\(selectedDish?.name ?? "")'?"),
                buttons: createDishActionSheetButtons()
            )
        }
    }
    
    private func showDishActionSheet(for dish: Dish) {
        selectedDish = dish
        showDishActionSheet = true
    }
    
    private func createDishActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        guard let dish = selectedDish else { return [.cancel()] }
        
        // Move to other categories
        for otherCategory in viewModel.categories where otherCategory.id != category.id {
            buttons.append(.default(Text("Move to \(otherCategory.name)")) {
                viewModel.updateDishCategory(dishID: dish.id, categoryID: otherCategory.id)
            })
        }
        
        // Remove from current category
        buttons.append(.default(Text("Remove from \(category.name)")) {
            viewModel.updateDishCategory(dishID: dish.id, categoryID: nil)
        })
        
        // Delete option
        buttons.append(.destructive(Text("Delete Recipe")) {
            deleteDish(dish)
        })
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func deleteDish(_ dish: Dish) {
        viewModel.deleteDish(dish)
    }
}

struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagementView(viewModel: DishViewModel())
    }
} 