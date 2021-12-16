//
//  Strings.swift
//  Imagine
//
//  Created by Don Malte on 28.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

struct Strings {
    
    // ImagineCommunityVC
    
    static let justFinishedHeader = "Just finished"
    
    // MARK: - VoteProposalVC
    
    static let proposal = NSLocalizedString("campaignVC_title", comment: "Proposal")
    static let proposalIntroDescription = NSLocalizedString("proposalIntroDescription", comment: "Lets decide together to get this to work...")
    static let proposalButtonText = NSLocalizedString("proposalButtonText", comment: "Share your idea")
    
    
    // MARK: - CampaignVC
    
    static let proposalOpen = NSLocalizedString("campaignVC_segment_open_proposal", comment: "Open")
    static let proposalFinished = NSLocalizedString("campaignVC_segment_done_proposal", comment: "Finished")
    
    // MARK: - Side Menu
    
    static let sideMenuNotification = NSLocalizedString("sideMenu_notifications_label", comment: "notifications:")
    static let sideMenuChats = NSLocalizedString("sideMenu_chats_label", comment: "chats")
    static let sideMenuDeleteAll = NSLocalizedString("sideMenu_notifications_delete_label", comment: "delete all")
    static let sideMenuFriends = NSLocalizedString("sideMenu_friends_label", comment: "friends")
    static let sideMenuSaved = NSLocalizedString("sideMenu_saved_label", comment: "saved")
}
