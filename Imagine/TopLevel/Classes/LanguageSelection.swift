//
//  LanguageSelection.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import Foundation

enum Language {
    case german
    case english
}

class LanguageSelection {
    let defaults = UserDefaults.standard
    let pre = Locale.preferredLanguages[0]
    
    func getLanguage() -> Language {
        if let language = defaults.string(forKey: "languageSelection") {
            
            return language == "de" ? .german : .english
        }
        
        // Return english as default
        return .english
    }
}
