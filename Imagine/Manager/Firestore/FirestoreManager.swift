//
//  FirestoreManager.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum FeedType {
    case main, user, saved
}

class FirestoreManager {
    
    let db = Firestore.firestore()
    
    var lastSnapshot: QueryDocumentSnapshot?
    
    static let shared = FirestoreManager()
    
    init() {
        
    }
    
}

// Fetch
extension FirestoreManager {
    
    func getPosts(for type: FeedType, completion: @escaping ([Post]?) -> Void) {
        let postQuery = FirestoreReference.collectionRef(.posts)
        
        if let lastSnap = lastSnapshot {
            postQuery.start(atDocument: lastSnap)
        }
        
        decode(query: postQuery) { (result: Result<[Post], Error>) in
            switch result {
            case .success(let posts):
                print("posts: ", posts)
                completion(posts)
            case .failure(let failure):
                print("failure: ", failure.localizedDescription)
            }
        }
    }
    
    func decode<T: Decodable>(query: Query, completion: @escaping (Result<[T], Error>) -> Void) {
        
        query.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                completion(.failure(error ?? FirestoreError.brokenAppleCredential))
                return
            }
            
            let objects = documents.compactMap { queryDocumentSnapshot -> T? in
                try? queryDocumentSnapshot.data(as: T.self)
            }
            
            self.lastSnapshot = documents.last
            
            completion(.success(objects))
        }
    }
    
    static func decodeSingle<T: Decodable>(reference: DocumentReference, completion: @escaping (Result<T, Error>) -> Void) {
        
        reference.getDocument(as: T.self) { (result: Result<T, Error>) in
            switch result {
            case .success(let object):
                completion(.success(object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
