//
//  StringExtensions.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

// MARK: - String

extension String {
    
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
            else { return ("\"", "\"") }

        return (bQuote, eQuote)
    }

    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }
    
    var customFormat: String {
        self.trimmingCharacters(in: .newlines).replacingOccurrences(of: "\n", with: "\\n")  // Save line breaks in a way that we can extract them later
    }
}


import AVFoundation

// MARK: - URL Stuff
extension String {
    func getURLVideoSize() -> CGSize {
        guard let url = URL(string: self), let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return CGSize.zero }
        let size = track.naturalSize.applying(track.preferredTransform)
        
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    var imgurID: String? {
        // Better pattern possible, couldnt find solution for an "logical or" for "gallery/" und ".com/"
        
        if self.contains("imgur") {
            if self.contains("gallery") {
                print("Eine Galerie")
                
                let pattern = "(?<=gallery/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            } else {
                print("Keine Galerie")
                
                let pattern = "(?<=.com/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            }
        } else {
            print("Not an Imgur link")
            return nil
        }
    }
    
    var youtubeID: String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, range: range) else {
            return nil
        }
        
        return (self as NSString).substring(with: result.range)
    }
}
