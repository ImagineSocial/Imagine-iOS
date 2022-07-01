//
//  Firestore.swift
//  Imagine
//
//  Created by Don Malte on 01.07.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension QueryDocumentSnapshot {
    func timestamp() -> Timestamp {
        let data = self.data()
        guard let createdAt = data["createdAt"] as? Timestamp else {
            
            return Timestamp(date: Date())
        }
        
        return createdAt
    }
}

extension Query {
    func addFirestoreQuery(_ firestoreQuery: FirestoreQuery) -> Query {
        var query: Query
        if let equalTo = firestoreQuery.equalTo {
            query = self.whereField(firestoreQuery.field, isEqualTo: equalTo)
        } else {
            query = self.order(by: firestoreQuery.field, descending: firestoreQuery.descending)
        }
        
        if let limit = firestoreQuery.limit {
            query = self.limit(to: limit)
        }
        
        return query
    }
}

extension CollectionReference {
    func addQuery(_ firestoreQuery: FirestoreQuery) -> Query {
        var query: Query
        if let equalTo = firestoreQuery.equalTo {
            query = self.whereField(firestoreQuery.field, isEqualTo: equalTo)
        } else {
            query = self.order(by: firestoreQuery.field, descending: firestoreQuery.descending)
        }
        
        if let limit = firestoreQuery.limit {
            query = self.limit(to: limit)
        }
        
        return query
    }
}
