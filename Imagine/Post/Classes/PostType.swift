//
//  PostType.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

/// An enum that declares the type of a Post object
enum PostType: String, Codable {
    case picture
    case link
    case thought
    case repost
    case translation
    case youTubeVideo
    case GIF
    case multiPicture
    case panorama
    case music
    case singleTopic
    case topTopicCell
    case nothingPostedYet
}
