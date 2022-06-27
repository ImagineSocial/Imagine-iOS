//
//  AuthenticationManager.swift
//  Imagine
//
//  Created by Don Malte on 14.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthenticationManager {
    
    static let shared = AuthenticationManager()
   
    var userFetchCompleted = false
    
    var user: User?
    var userID = Auth.auth().currentUser?.uid
    
    var isLoggedIn: Bool {
        user != nil
    }
    
    init() {
        getUser()
    }
    
    private func getUser() {
        if let userID = Auth.auth().currentUser?.uid {
            let userRef = FirestoreRequest.shared.db.collection("Users").document(userID)
            
            userRef.getDocument(completion: { (document, err) in
                if let error = err {
                    print("We got an error with a user: \(error.localizedDescription)")
                } else {
                    if let document = document {
                        self.generateUser(document: document) { user in
                            self.user = user
                        }
                    }
                }
            })
        }
    }
    
    func generateUser(document: DocumentSnapshot, completion: @escaping (User?) -> Void) {
        guard let docData = document.data() else {
            completion(nil)
            return
        }
        
        let user = User(userID: document.documentID)
        
        user.name = docData["name"] as? String
        user.instagramLink = docData["instagramLink"] as? String
        user.instagramDescription = docData["instagramDescription"] as? String
        
        user.patreonLink = docData["patreonLink"] as? String
        user.patreonDescription = docData["patreonDescription"] as? String
        
        user.youTubeLink = docData["youTubeLink"] as? String
        user.youTubeDescription = docData["youTubeDescription"] as? String
        user.twitterLink = docData["twitterLink"] as? String
        user.twitterDescription = docData["twitterDescription"] as? String
        user.songwhipLink = docData["songwhipLink"] as? String
        user.songwhipDescription = docData["songwhipDescription"] as? String
        
        user.locationName = docData["locationName"] as? String
        user.locationIsPublic = docData["locationIsPublic"] as? Bool ?? false
        
        user.imageURL = docData["profilePictureURL"] as? String
        user.statusText = docData["statusText"] as? String
        user.blocked = docData["blocked"] as? [String] ?? nil
        
        completion(user)
    }
}
