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
            return dateFormatter.weekdaySymbols[weekday - 1]
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
        
        var feedString: String
        let date = Date()
        
        switch monthsAgo {
        case 0:
            if calendar.isDateInToday(self) {
                if date.hoursLater(than: self) == 0 {
                    feedString = Strings.momentsAgo
                } else {
                    feedString = String.localizedStringWithFormat(Strings.xHoursAgo, date.hoursLater(than: self))
                }
            } else if calendar.isDateInYesterday(self){
                feedString = Strings.yesterday
            } else {
                if self.daysAgo == 1 {
                    feedString = Strings.yesterday
                } else {
                    feedString = String.localizedStringWithFormat(Strings.xDaysAgo, self.daysAgo)
                }
            }
        case 1:
            feedString = Strings.oneMonthAgo
            case 2,3,4,5,6,7,8,9,10,11,12:
            feedString = String.localizedStringWithFormat(Strings.xMonthsAgo, self.monthsAgo)
        default:
            feedString = self.yearsAgo == 1 ? Strings.oneYearAgo : String.localizedStringWithFormat(Strings.xYearsAgo, self.yearsAgo)
        }
        
        return feedString
    }
    
    
    func year() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let stringDate = dateFormatter.string(from: self)
        
        return stringDate
    }
}
