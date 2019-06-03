//
//  ChatModels.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import MessengerKit

 public class ChatUser: MSGUser {
    
    public var displayName: String
    
    public var avatar: UIImage?
    
    public var avatarUrl: URL?
    
    public var isSender: Bool
    
    public init(displayName: String, avatar: UIImage?, avatarURL: URL?, isSender: Bool) {
        self.displayName = displayName
        self.avatar = avatar
        self.avatarUrl = avatarURL
        self.isSender = isSender
    }
}

