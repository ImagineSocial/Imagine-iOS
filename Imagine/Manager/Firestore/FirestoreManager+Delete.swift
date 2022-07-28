//
//  FirestoreManager+Delete.swift
//  Imagine
//
//  Created by Don Malte on 28.07.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension FirestoreManager {
    static func delete(_ documentReference: DocumentReference, completion: @escaping (Error?) -> Void) {
        documentReference.delete(completion: completion)
    }
}
