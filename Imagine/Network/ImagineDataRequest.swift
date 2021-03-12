//
//  ImagineDataRequest.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Firebase
import UIKit

class ImagineDataRequest {
    
    private let db = Firestore.firestore()
    
    public func getReportData(returnData: @escaping (ReportData?) -> Void) {
        
        let dataRef = db.collection("TopTopicData").document("TopTopicData")
        let language = LanguageSelection().getLanguage()
        
        dataRef.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        guard let userCountDE = data["userCountDE"] as? Int,
                              let userCountEN = data["userCountEN"] as? Int,
                              let earnings = data["earnings"] as? Double,
                              let expenses = data["expenses"] as? Double,
                              let fundDonations = data["fundDonations"] as? Double
                        else {
                            print("Error: Couldnt get the right imagineReport Data")
                            returnData(nil)
                            return
                        }
                        
                        var userCount:Int!
                        if language == .german {
                            userCount = userCountDE
                        } else {
                            userCount = userCountEN
                        }
                        
                        let report = ReportData(userCount: userCount, earnings: earnings, expenses: expenses, donations: fundDonations)
                        
                        returnData(report)
                    }
                }
            }
        }
    }
}
