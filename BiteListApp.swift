//
//  BiteListApp.swift
//  BiteList
//
//  Created by Ranjana Raghavan on 7/8/25.
//

import SwiftUI

@main
struct BiteListApp: App {
    init() {
        print("🏠 Current working directory: \(FileManager.default.currentDirectoryPath)")
    }
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
