//
//  Date.swift
//  Imagine
//
//  Created by Don Malte on 01.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

extension Date {
    
    func formatRelativeString() -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true
        
        if calendar.isDateInToday(self) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else if calendar.isDateInYesterday(self){
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
            let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
            return dateFormatter.weekdaySymbols[weekday-1]
        } else {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
        }
        
        return dateFormatter.string(from: self)
    }
    
    func formatForFeed() -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true
        
        var feedString = ""
        let date = Date()
        
        // To-do: the date variable is not in the correct time zone??
        
        if calendar.isDateInToday(self) {
            
            if date.hoursLater(than: self) == 0 {
                feedString = NSLocalizedString("few_moments_ago", comment: "few_moments_ago")
            } else {
                let hoursAgoString = NSLocalizedString("%d hours ago", comment: "How many hours is the post old")
                
                feedString = String.localizedStringWithFormat(hoursAgoString, date.hoursLater(than: self))
            }
            
        } else if calendar.isDateInYesterday(self){
            feedString = NSLocalizedString("yesterday", comment: "yesterday")
        } else {
            if self.daysAgo == 1 {
                feedString = NSLocalizedString("yesterday", comment: "yesterday")
            } else {
                let daysAgoString = NSLocalizedString("%d days ago", comment: "How many days is the post old")
                
                feedString = String.localizedStringWithFormat(daysAgoString, self.daysAgo)
            }
        }
        
        return feedString
    }
}
