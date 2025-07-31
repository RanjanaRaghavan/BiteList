//
//  HomeView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = DishViewModel()
    @State private var showAddDish = false
    @State private var showAddCategory = false
    @State private var showCategoryManagement = false
    @State private var showActionSheet = false
    @State private var actionSheetType: ActionSheetType = .addOptions
    @State private var selectedDish: Dish?
    @State private var selectedCategory: Category?
    
    enum ActionSheetType {
        case addOptions
        case dishOptions
        case categoryOptions
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Categories Section
                        if !viewModel.categories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Categories")
                                        .font(.title2)
                                        .bold()
                                    
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(viewModel.categories) { category in
                                        NavigationLink(destination: CategoryDetailView(category: category, viewModel: viewModel)) {
                                            CategoryCardView(category: category, viewModel: viewModel)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .simultaneousGesture(
                                            LongPressGesture(minimumDuration: 0.5)
                                                .onEnded { _ in
                                                    withAnimation(.easeInOut(duration: 0.1)) {
                                                        print("🔧 Category long-press detected for: \(category.name)")
                                                        actionSheetType = .categoryOptions
                                                        selectedCategory = category
                                                        showActionSheet = true
                                                    }
                                                }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // All Dishes Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("All Recipes")
                                    .font(.title2)
                                    .bold()
                                
                                Spacer()
                            }
                            
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.dishes) { dish in
                                    NavigationLink(destination: DishDetailView(viewModel: viewModel, dish: dish)) {
                                        RecipeTile(dish: dish)
                                            .overlay(
                                                // Category indicator
                                                HStack {
                                                    if let category = viewModel.categoryForDish(dish) {
                                                        HStack(spacing: 4) {
                                                            Circle()
                                                                .fill(category.swiftUIColor)
                                                                .frame(width: 8, height: 8)
                                                            Text(category.name)
                                                                .font(.caption2)
                                                                .foregroundColor(.white)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.black.opacity(0.6))
                                                                .cornerRadius(4)
                                                        }
                                                        .padding(8)
                                                    }
                                                    Spacer()
                                                }
                                                , alignment: .topLeading
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onEnded { _ in
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    print("🔧 Dish long-press detected for: \(dish.name)")
                                                    actionSheetType = .dishOptions
                                                    selectedDish = dish
                                                    showActionSheet = true
                                                }
                                            }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
                
                // Add Button with Options
                Button(action: { 
                    print("🔧 Plus button tapped")
                    actionSheetType = .addOptions
                    showActionSheet = true 
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("Add")
            }
            .navigationTitle("Recipes")
            .sheet(isPresented: $showAddDish) {
                AddDishView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(viewModel: viewModel)
            }
            .actionSheet(isPresented: $showActionSheet) {
                switch actionSheetType {
                case .addOptions:
                    return ActionSheet(
                        title: Text("Add New"),
                        message: Text("What would you like to add?"),
                        buttons: [
                            .default(Text("Add Recipe")) {
                                print("🔧 Add Recipe selected")
                                showAddDish = true
                            },
                            .default(Text("Add Category")) {
                                print("🔧 Add Category selected")
                                showAddCategory = true
                            },
                            .cancel()
                        ]
                    )
                case .dishOptions:
                    return ActionSheet(
                        title: Text("Recipe Options"),
                        message: Text("What would you like to do with '\(selectedDish?.name ?? "")'?"),
                        buttons: createDishActionSheetButtons()
                    )
                case .categoryOptions:
                    return ActionSheet(
                        title: Text("Category Options"),
                        message: Text("What would you like to do with '\(selectedCategory?.name ?? "")'?"),
                        buttons: createCategoryActionSheetButtons()
                    )
                }
            }
        }
    }
    
    // MARK: - Action Sheet Methods
    
    private func createDishActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        guard let dish = selectedDish else { return [.cancel()] }
        
        // Category management options
        if let currentCategory = viewModel.categoryForDish(dish) {
            // Dish is in a category - offer to move to other categories or remove
            for category in viewModel.categories where category.id != currentCategory.id {
                buttons.append(.default(Text("Move to \(category.name)")) {
                    viewModel.updateDishCategory(dishID: dish.id, categoryID: category.id)
                })
            }
            buttons.append(.default(Text("Remove from \(currentCategory.name)")) {
                viewModel.updateDishCategory(dishID: dish.id, categoryID: nil)
            })
        } else {
            // Dish is not categorized - offer to add to categories
            for category in viewModel.categories {
                buttons.append(.default(Text("Move to \(category.name)")) {
                    viewModel.updateDishCategory(dishID: dish.id, categoryID: category.id)
                })
            }
        }
        
        // Delete option
        buttons.append(.destructive(Text("Delete Recipe")) {
            deleteDish(dish)
        })
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func createCategoryActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        guard let category = selectedCategory else { return [.cancel()] }
        
        let dishCount = viewModel.dishesInCategory(category).count
        
        buttons.append(.destructive(Text("Delete Category (\(dishCount) recipes will be moved to main page)")) {
            deleteCategory(category)
        })
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func deleteDish(_ dish: Dish) {
        viewModel.deleteDish(dish)
    }
    
    private func deleteCategory(_ category: Category) {
        // Show confirmation alert before deleting
        // For now, we'll delete directly. In a real app, you might want a confirmation alert
        viewModel.deleteCategory(category)
    }
}

struct CategoryCardView: View {
    let category: Category
    @ObservedObject var viewModel: DishViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Text("\(viewModel.dishesInCategory(category).count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .frame(height: 80)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
