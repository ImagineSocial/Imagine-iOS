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
    var dataPath = ""
    let db = Firestore.firestore()
    
    
    
    func getData(get: String, returnData: @escaping ([Any]) -> Void) {
        // "get" Variable kann "campaign" für CommunityEntscheidungen, "jobOffer" für Hilfe der Community und "fact" für Fakten Dings sein
        
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        var list = [Any]()
        
        
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
        } else if get == "facts" {
            list = [Fact]()
            dataPath = "Facts"
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
                } else if get == "facts" {
                    guard let name = documentData["name"] as? String,
                    let createTimestamp = documentData["createDate"] as? Timestamp,
                    let imageURL = documentData["imageURL"] as? String
                    
                        else {
                            continue
                    }
                    
                    // Datum vom Timestamp umwandeln
                    let formatter = DateFormatter()
                    let date:Date = createTimestamp.dateValue()
                    formatter.dateFormat = "dd MM yyyy HH:mm"
                    let stringDate = formatter.string(from: date)
                    
                    
                    
                    let fact = Fact()
                    fact.title = name
                    fact.createDate = stringDate
                    fact.documentID = documentID
                    fact.imageURL = imageURL

                    list.append(fact)
                    
                }
            }
            returnData(list)
        }
    }
    
    func getDeepData(get: String, documentID: String, returnData: @escaping ([Any]) -> Void) {
        
        var argumentList = [Argument]()
        
        print("Hier wird geaden mit ID:", documentID)
        self.db.collection(get).document(documentID).collection("arguments").getDocuments(completion: { (snap, err) in
            for document in snap!.documents {
                
                let docData = document.data()
                let documentID = document.documentID
                
                guard let source = docData["source"] as? [String],
                    let title = docData["title"] as? String,
                    let proOrContra = docData["proOrContra"] as? String,
                    let description = docData["description"] as? String
                    else {
                        continue    // Falls er das nicht als (String) zuordnen kann
                }
                
                let argument = Argument()
                argument.source = source
                argument.title = title
                argument.description = description
                argument.proOrContra = proOrContra
                argument.documentID = documentID
                
                argumentList.append(argument)
            }
            let argument = Argument()
            argument.source = [""]
            argument.title = "Füge ein Argument hinzu!"
            argument.description = "Wenn du einen validen Punkt zu der Diskussion hinzufügen kannst würden wir uns sehr freuen!"
            argument.proOrContra = "pro"
            
            argumentList.append(argument)
            
            let conArgument = Argument()
            conArgument.source = [""]
            conArgument.title = "Füge ein Argument hinzu!"
            conArgument.description = "Wenn du einen validen Punkt zu der Diskussion hinzufügen kannst würden wir uns sehr freuen!"
            conArgument.proOrContra = "contra"
            
            argumentList.append(conArgument)
            
            returnData(argumentList)
        })
    }
    
    func getDeepestArgument(factID: String, argumentID: String , returnData: @escaping ([Any]) -> Void) {
        
        var argumentList = [Argument]()
        
        let argumentPath = self.db.collection("Facts").document(factID).collection("arguments").document(argumentID).collection("arguments")
            
            argumentPath.getDocuments(completion: { (snap, err) in
                
                if err != nil {
                    print("Wir haben einen Error bei den tiefen Argumenten: ", err?.localizedDescription)
                }
                
            for document in snap!.documents {
                
                let docData = document.data()
                
                guard let source = docData["source"] as? [String],
                    let title = docData["title"] as? String,
                    let proOrContra = docData["proOrContra"] as? String,
                    let description = docData["description"] as? String
                    else {
                        continue    // Falls er das nicht als (String) zuordnen kann
                }
                
                let argument = Argument()
                argument.source = source
                argument.title = title
                argument.description = description
                argument.proOrContra = proOrContra
                
                argumentList.append(argument)
            }
            
                let argument = Argument()
                argument.source = [""]
                argument.title = "Füge ein Argument hinzu!"
                argument.description = "Wenn du einen validen Punkt zu der Diskussion hinzufügen kannst würden wir uns sehr freuen!"
                argument.proOrContra = "pro"
                
                argumentList.append(argument)
            
            returnData(argumentList)
        })
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


class Fact {
    var title = ""
    var createDate = ""
    var documentID = ""
    var imageURL = ""
    var arguments: [Argument] = []
}

class Argument {
    var source:[String] = []
    var proOrContra = ""
    var title = ""
    var description = ""
    var documentID = ""
    var contraArguments: [Argument] = []
}
