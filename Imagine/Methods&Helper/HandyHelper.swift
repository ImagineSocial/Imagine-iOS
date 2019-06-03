//
//  HandyHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore


class HandyHelper {
    
    func getDateAsTimestamp() -> Timestamp {
                let date = Date()
        let timestamp = Timestamp(date: date)
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd MM yyyy HH:mm"
//        let stringDate = formatter.string(from: date)
//        if let result = formatter.date(from: stringDate) {
//            let dateTimestamp :Timestamp = Timestamp(date: result)  // Hat keine Nanoseconds
//            return dateTimestamp
//        }
        return timestamp
    }
    
    func getStringDate(timestamp: Timestamp) -> String {
        // Timestamp umwandeln
        let formatter = DateFormatter()
        let date:Date = timestamp.dateValue()
        formatter.dateFormat = "dd MM yyyy HH:mm"
        let stringDate = formatter.string(from: date)
        
        return stringDate
    }
}
