//
//  FirestoreManager+Upload.swift
//  Imagine
//
//  Created by Don Malte on 11.06.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

extension FirestoreManager {
    static func uploadObject<T: Codable>(object: T, documentReference: DocumentReference, completion: @escaping (Error?) -> Void) {
        do {
            // setData updates values or creates them if they don't exist
            try documentReference.setData(from: object, merge: true)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    static func batchUploadPostData(_ data: [PostData], collectionReference: CollectionReference, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        data.forEach { element in
            
            if let encodedElement = try? Firestore.Encoder().encode(element), let id = element.id {
                let documentReference = collectionReference.document(id)
                batch.setData(encodedElement, forDocument: documentReference)
            }
        }
        
        batch.commit(completion: completion)
    }
    
    static func batchUploadCommunities(_ communities: [Community], collectionReference: CollectionReference, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        communities.forEach { community in
            
            if let encodedElement = try? Firestore.Encoder().encode(community), let id = community.id {
                let documentReference = collectionReference.document(id)
                batch.setData(encodedElement, forDocument: documentReference)
            }
        }
        
        batch.commit(completion: completion)
    }
}
