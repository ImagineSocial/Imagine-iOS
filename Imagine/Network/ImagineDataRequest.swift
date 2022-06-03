//
//  ImagineDataRequest.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import FirebaseFirestore
import UIKit

class ImagineDataRequest {
    
    private let db = FirestoreRequest.shared.db
    
    //MARK:- Get Monthly Report
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
                        if language == .de {
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
    
    
    //MARK:- Get FinishedWork
    public func getFinishedWorkload(returnData: @escaping ([FinishedWorkItem]?) -> Void) {
        
        let dataRef = db.collection("TopTopicData").document("FinishedProjects").collection("finishedProjects").order(by: "createDate", descending: true)
        
        dataRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    
                    var workItems = [FinishedWorkItem]()
                    
                    for document in snap.documents {
                        let data = document.data()
                        
                        guard let title = data["title"] as? String,
                              let description = data["description"] as? String,
                              let createDate = data["createDate"] as? Timestamp
                        else {
                            returnData(nil)
                            return
                        }
                        let date = createDate.dateValue()
                        let workItem = FinishedWorkItem(title: title, description: description, createDate: date)
                        
                        if let id = data["campaignID"] as? String {
                            workItem.campaignID = id
                        }
                        
                        workItems.append(workItem)
                    }
                    
                    returnData(workItems)
                }
            }
        }
    }
    
    //MARK:- Get Campaigns
    func getCampaigns(onlyFinishedCampaigns: Bool, returnCampaigns: @escaping ([Campaign]?) -> Void) {

        var ref: Query!
            
        if onlyFinishedCampaigns {
            ref = db.collection("Data").document("en").collection("campaigns").whereField("state", isEqualTo: "done")
        } else {
            ref = db.collection("Data").document("en").collection("campaigns").whereField("state", isEqualTo: "open").order(by: "supporter", descending: true)
        }

        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                returnCampaigns(nil)
            } else if let snap = snap {
                
                var campaigns = [Campaign]()
                
                for document in snap.documents {
                    let data = document.data()
                    
                    if let campaign = ImagineDataHelper.getCampaign(documentID: document.documentID, documentData: data) {
                        campaigns.append(campaign)
                    } else {
                        continue
                    }
                }
                returnCampaigns(campaigns)
            }
        }
    }
    
    //MARK:- Get Single Campaign
    func getSingleCampaign(documentID: String, returnCampaign: @escaping (Campaign?) -> Void) {
        let ref = db.collection("Data").document("en").collection("campaigns").document(documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap, let data = snap.data() {
                    
                    if let campaign = ImagineDataHelper.getCampaign(documentID: documentID, documentData: data) {
                        returnCampaign(campaign)
                    } else {
                        returnCampaign(nil)
                    }
                }
            }
        }
    }
}
