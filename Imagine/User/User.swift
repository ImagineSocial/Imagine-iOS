//
//  User.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestoreSwift

class User: Codable {
    
    init(userID: String) {
        self.uid = userID
    }
    
    //MARK: - Variables
    
    @DocumentID var uid: String?
    var name: String?
    var imageURL: String?
    var blocked: [String]?
    var statusText: String?
    
    //Social Media Links
    var instagramLink: String?
    var instagramDescription: String?
    var patreonLink: String?
    var patreonDescription: String?
    var youTubeLink: String?
    var youTubeDescription: String?
    var twitterLink: String?
    var twitterDescription: String?
    var songwhipLink: String?
    var songwhipDescription: String?
    
    //location
    var locationName: String?
    var locationIsPublic = false
    
    enum CodingKeys: String, CodingKey {
        case imageURL = "profilePictureURL"
        case name, statusText, blocked, instagramLink, instagramDescription, patreonLink, patreonDescription, youTubeLink, youTubeDescription, twitterLink, twitterDescription, songwhipLink, songwhipDescription, locationName, locationIsPublic
    }
    
    
    //MARK: - Get User
    func loadUser(completion: @escaping (User?) -> Void) {
        
        let reference = FirestoreReference.documentRef(.users, documentID: uid)
        
        FirestoreManager.decodeSingle(reference: reference) { (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                completion(user)
            case .failure(let error):
                completion(nil)
                print("We got an error: \(error.localizedDescription)")
            }
        }
    }
}
