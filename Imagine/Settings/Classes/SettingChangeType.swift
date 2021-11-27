//
//  SettingChangeType.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

enum SettingChangeType {
    
    //Topic
    case changeTopicTitle
    case changeTopicAddOnsAsFirstView
    case changeTopicPicture
    case changeTopicDescription
    
    //User
    case changeUserPicture
    case changeUserStatusText
    case changeUserAge
    case changeUserLocation
    case changeUserLocationPublicity
    
    //User Social Media
    case changeUserInstagramLink
    case changeUserInstagramDescription
    case changeUserPatreonLink
    case changeUserPatreonDescription
    case changeUserYouTubeLink
    case changeUserYouTubeDescription
    case changeUserTwitterLink
    case changeUserTwitterDescription
    case changeUserSongwhipLink
    case changeUserSongwhipDescription
    
    //AddOn
    case changeAddOnPicture
    case changeAddOnTitle
    case changeAddOnDescription
    case changeAddOnItemOrderArray
}
