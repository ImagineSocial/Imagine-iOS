//
//  FirestoreManager+Decode.swift
//  Imagine
//
//  Created by Don Malte on 19.08.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension FirestoreManager {
    
    func decode<T: Decodable>(query: Query, saveSnapshots: Bool = true, completion: @escaping (Result<[T], Error>) -> Void) {
        
        query.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                completion(.failure(error ?? FirestoreError.brokenAppleCredential))
                return
            }

            let objects = documents.compactMap { queryDocumentSnapshot -> T? in
                try? queryDocumentSnapshot.data(as: T.self)
            }
                        
            if saveSnapshots, !documents.isEmpty {
                self.startAfterSnapshot = self.endBeforeSnapshot  // If there is already an endBeforeSnapshot, then we want this date as the starting point for the next query
                self.endBeforeSnapshot = documents.last // The topic posts shall be fetched up until this date -> Fetch
            }
            
            self.activateSubcollections(for: objects)
            completion(.success(objects))
        }
    }
    
    func decodeSingle<T: Decodable>(reference: DocumentReference, completion: @escaping (Result<T, Error>) -> Void) {
        reference.getDocument(as: T.self) { (result: Result<T, Error>) in
            switch result {
            case .success(let object):
                self.activateSubcollections(for: [object])
                completion(.success(object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func activateSubcollections(for objects: [Any]) {
        if let posts = objects as? [Post] {
            posts.forEach { $0.loadUser() }
        }
    }

}
