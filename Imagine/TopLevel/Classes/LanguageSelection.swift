//
//  LanguageSelection.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import Foundation

enum Language: String, Codable {
    case de
    case en
}

class LanguageSelection {
    static let defaults = UserDefaults.standard
    
    static var language: Language {
        if let language = defaults.string(forKey: "languageSelection") {
            
            return language == "de" ? .de : .en
        }
        
        // Return english as default
        return .en
    }
}
