//
//  Strings.swift
//  Imagine
//
//  Created by Don Malte on 28.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

struct Strings {
    
    // MARK: - Community
    
    static let discussion = NSLocalizedString("discussion", comment: "discussion")
    static let feed = "Feed"
    static let topics = NSLocalizedString("topics", comment: "topics")
    
    // MARK: - Feed
    
    static let momentsAgo = NSLocalizedString("few_moments_ago", comment: "few_moments_ago")
    static let oneMonthAgo = NSLocalizedString("oneMonthAgo", comment: "One month ago")
    static let oneYearAgo = NSLocalizedString("oneYearAgo", comment: "One year ago")
    static let yesterday = NSLocalizedString("yesterday", comment: "yesterday")
    static let xDaysAgo = NSLocalizedString("%d days ago", comment: "How many days is the post old")
    static let xHoursAgo = NSLocalizedString("%d hours ago", comment: "How many hours is the post old")
    static let xMonthsAgo = NSLocalizedString("%d months ago", comment: "how many months is the post old")
    static let xYearsAgo = NSLocalizedString("%d years ago", comment: "How many years is the post old")
    
    // MARK: - ImagineCommunityVC
    
    static let justFinishedHeader = "Just finished"
    
    // MARK: - VoteProposalVC
    
    static let proposal = NSLocalizedString("campaignVC_title", comment: "Proposal")
    static let proposalIntroDescription = NSLocalizedString("proposalIntroDescription", comment: "Lets decide together to get this to work...")
    static let proposalButtonText = NSLocalizedString("proposalButtonText", comment: "Share your idea")
    
    
    // MARK: - CampaignVC
    
    static let proposalOpen = NSLocalizedString("campaignVC_segment_open_proposal", comment: "Open")
    static let proposalFinished = NSLocalizedString("campaignVC_segment_done_proposal", comment: "Finished")
    
    // MARK: - NewPost
    
    static let text = NSLocalizedString("newPost_segmentControl_label_text", comment: "")
    static let picture = NSLocalizedString("newPost_segmentControl_label_picture", comment: "")
    static let link = NSLocalizedString("newPost_segmentControl_label_link", comment: "")
    
    
    // MARK: - Side Menu
    
    static let sideMenuNotification = NSLocalizedString("sideMenu_notifications_label", comment: "notifications:")
    static let sideMenuChats = NSLocalizedString("sideMenu_chats_label", comment: "chats")
    static let sideMenuDeleteAll = NSLocalizedString("sideMenu_notifications_delete_label", comment: "delete all")
    static let sideMenuFriends = NSLocalizedString("sideMenu_friends_label", comment: "friends")
    static let sideMenuSaved = NSLocalizedString("sideMenu_saved_label", comment: "saved")
}
