//
//  DataHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

class DataHelper {
    
    // Überall noch eine Wichtigkeitsvariable einfügen
    
    func getData(get: String, returnData: @escaping ([Any]) -> Void) {
        
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        var list = [Any]()
        var dataPath = ""
        
        if get == "campaign" {
            list = [Campaign]()
            dataPath = "Campaigns"
        } else if get == "jobOffer" {
            list = [JobOffer]()
            dataPath = "JobOffers"
            
            let jobOffer = JobOffer()   // Der erste Eintrag
            jobOffer.title = "Wir brauchen dich!"
            jobOffer.cellText = "Wenn du glaubst, mit deinem Wissen oder Erfahrung kannst du uns helfen, aber es gibt keine passende Ausschreibung, gib uns Bescheid! Wir sind auf klüge Köpfe angewiesen!"
            jobOffer.documentID = ""
            jobOffer.createDate = "15.05.2019"
            jobOffer.interested = 10
            
            list.append(jobOffer)
        }
        
        
        
        db.collection(dataPath).getDocuments { (querySnapshot, error) in
            
            for document in querySnapshot!.documents {
                
                let documentID = document.documentID
                let documentData = document.data()
                
                if get == "campaign" {
                    if let campaignType = documentData["campaignType"] as? String {
                        if campaignType == "normal" {
                            
                            guard let title = documentData["campaignTitle"] as? String,
                                let shortBody = documentData["campaignShortBody"] as? String,
                                let createTimestamp = documentData["campaignCreateTime"] as? Timestamp,
                                let supporter = documentData["campaignSupporter"] as? Int,
                                let opposition = documentData["campaignOpposition"] as? Int
                                else {
                                    continue    // Falls er das nicht als (String) zuordnen kann
                            }
                            
                            // Datum vom Timestamp umwandeln
                            let formatter = DateFormatter()
                            let date:Date = createTimestamp.dateValue()
                            formatter.dateFormat = "dd MM yyyy HH:mm"
                            let stringDate = formatter.string(from: date)
                            
                            let campaign = Campaign()       // Erst neue Campaign erstellen
                            campaign.title = title      // Dann die Sachen zuordnen
                            campaign.cellText = shortBody
                            campaign.documentID = documentID
                            campaign.createDate = stringDate
                            campaign.supporter = supporter
                            campaign.opposition = opposition
                            
                            
                            list.append(campaign)
                            
                        }
                    }
                } else if get == "jobOffer" {
                    guard let title = documentData["jobTitle"] as? String,
                        let shortBody = documentData["jobShortBody"] as? String,
                        let createTime = documentData["jobCreateTime"] as? String,
                        let interestedCount = documentData["interestedInJob"] as? Int
                        else {
                            continue    // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    
                    let jobOffer = JobOffer()       // Erst neue Campaign erstellen
                    jobOffer.title = title      // Dann die Sachen zuordnen
                    jobOffer.cellText = shortBody
                    jobOffer.documentID = documentID
                    jobOffer.createDate = createTime
                    jobOffer.interested = interestedCount
                    
                    list.append(jobOffer)
                }
            }
            returnData(list)
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

class Campaign {
    var title = ""
    var cellText = ""
    var descriptionText = ""
    var documentID = ""
    var createDate = ""
    var supporter = 0
    var opposition = 0
}
