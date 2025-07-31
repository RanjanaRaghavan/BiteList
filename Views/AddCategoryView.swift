//
//  AddCategoryView.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var viewModel: DishViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var selectedColor = "blue"
    
    private let availableColors = [
        ("blue", Color.blue),
        ("red", Color.red),
        ("green", Color.green),
        ("orange", Color.orange),
        ("purple", Color.purple),
        ("pink", Color.pink),
        ("yellow", Color.yellow),
        ("gray", Color.gray)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $categoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach(0..<4) { index in
                                    let colorData = availableColors[index]
                                    ColorButton(
                                        colorName: colorData.0,
                                        color: colorData.1,
                                        isSelected: selectedColor == colorData.0,
                                        onTap: {
                                            print("🔧 Color selected: \(colorData.0)")
                                            selectedColor = colorData.0
                                        }
                                    )
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(4..<8) { index in
                                    let colorData = availableColors[index]
                                    ColorButton(
                                        colorName: colorData.0,
                                        color: colorData.1,
                                        isSelected: selectedColor == colorData.0,
                                        onTap: {
                                            print("🔧 Color selected: \(colorData.0)")
                                            selectedColor = colorData.0
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Create Category") {
                        createCategory()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        print("🔧 Creating category: \(trimmedName) with color: \(selectedColor)")
        let newCategory = Category(name: trimmedName, color: selectedColor)
        viewModel.addCategory(newCategory)
        dismiss()
    }
}

struct ColorButton: View {
    let colorName: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
    }
}

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddCategoryView(viewModel: DishViewModel())
    }
} 