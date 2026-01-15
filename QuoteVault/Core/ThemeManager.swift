//
//  ThemeManager.swift
//  QuoteVault
//
//  Created by Mohd Sufiyan on 15/01/26.
//

import SwiftUI

@MainActor
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var selectedTheme: String = AppConstants.Theme.defaultTheme
    @Published var fontSize: Double = 16.0
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppConstants.Theme.defaultTheme
        fontSize = UserDefaults.standard.double(forKey: "fontSize")
        if fontSize == 0 {
            fontSize = 16.0
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
    }
    
    var accentColor: Color {
        switch selectedTheme {
        case AppConstants.Theme.blue:
            return .blue
        case AppConstants.Theme.purple:
            return .purple
        default:
            return .accentColor
        }
    }
}
