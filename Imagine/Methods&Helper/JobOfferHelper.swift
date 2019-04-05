//
//  JobOfferHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

class JobOfferHelper {
    
    func getJobOffers(returnJobOffers: @escaping ([JobOffer]) -> Void) {
        
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        var jobOffers = [JobOffer]()
        
        db.collection("JobOffers").getDocuments { (querySnapshot, error) in
            
            for document in querySnapshot!.documents {
                
                let documentID = document.documentID
                let documentData = document.data()
                
                        guard let title = documentData["jobTitle"] as? String,
                            let shortBody = documentData["jobShortBody"] as? String,
                            let createTime = documentData["jobCreateTime"] as? String,
                            let interestedCount = documentData["interestedInJob"] as? Int
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                
                        /*
                        // Datum vom Timestamp umwandeln
                        let formatter = DateFormatter()
                        let date:Date = createTimestamp.dateValue()
                        formatter.dateFormat = "dd MM yyyy HH:mm"
                        let stringDate = formatter.string(from: date)
                        */
                
                        let jobOffer = JobOffer()       // Erst neue Campaign erstellen
                        jobOffer.title = title      // Dann die Sachen zuordnen
                        jobOffer.cellText = shortBody
                        jobOffer.documentID = documentID
                        jobOffer.createDate = createTime
                        jobOffer.interested = interestedCount
                
                        
                        
                        jobOffers.append(jobOffer)
                        
                
            }
            returnJobOffers(jobOffers)
        }
    }
}

class JobOffer {
    var title = ""
    var cellText = ""
    var descriptionText = ""
    var documentID = ""
    var createDate = ""
    var interested = 0
}

