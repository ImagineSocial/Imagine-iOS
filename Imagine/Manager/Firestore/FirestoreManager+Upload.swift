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
            try documentReference.setData(from: object)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
