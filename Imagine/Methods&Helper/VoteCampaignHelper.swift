//
//  voteCampaignHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

class CampaignHelper {
    
    func getCampaigns(returnCampaigns: @escaping ([Campaign]) -> Void) {
        
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        var campaigns = [Campaign]()
        
        db.collection("Campaigns").getDocuments { (querySnapshot, error) in
            
            for document in querySnapshot!.documents {
                
                let documentID = document.documentID
                let documentData = document.data()
                
                
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
                        
                        
                        campaigns.append(campaign)
                        
                    }
                }
            }
            returnCampaigns(campaigns)
        }
    }
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
