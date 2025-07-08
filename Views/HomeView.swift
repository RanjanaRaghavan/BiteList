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
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.dishes) { dish in
                            NavigationLink(destination: DishDetailView(viewModel: viewModel, dish: dish)) {
                                RecipeTile(dish: dish)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                Button(action: { showAddDish = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("Add Dish")
            }
            .navigationTitle("Recipes")
            .sheet(isPresented: $showAddDish) {
                AddDishView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    HomeView()
}
