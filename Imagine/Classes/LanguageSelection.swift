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
        if let language = defaults.string(forKey: "languageSelection"){
            print("**Das ist die Value for key languageSelectui: \(language)")
            if language == "de" {
                return .german
            } else if language == "en" {
                return .english
            }
        } else if pre != "de" {
            print("**return english weil pre nicht deutsch ist")
            return .english
        } else {
            print("**return deutsch weil pre de ist")
            return .german
        }
        print("**return default englisch")
        return .english
    }
    
}
