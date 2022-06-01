//
//  ImagineDataHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

class ImagineDataHelper {
    
    
    static func getCampaign(documentID: String, documentData: [String: Any]) -> Campaign? {
        
        if let campaignType = documentData["type"] as? String {
            if campaignType == "normal" {
                
                guard let title = documentData["title"] as? String,
                      let shortBody = documentData["summary"] as? String,
                      let createTimestamp = documentData["createTime"] as? Timestamp,
                      let supporter = documentData["supporter"] as? Int,
                      let opposition = documentData["opposition"] as? Int,
                      let category = documentData["category"] as? String
                else {
                    return nil
                }
                
                let date = createTimestamp.dateValue()
                let stringDate = date.formatRelativeString()
                
                let campaign = Campaign()
                campaign.title = title
                campaign.cellText = shortBody
                campaign.documentID = documentID
                campaign.createDate = stringDate
                campaign.supporter = supporter
                campaign.opposition = opposition
                campaign.createTime = date
                campaign.category = self.getCampaignType(categoryString: category)
                
                if let description = documentData["description"] as? String {
                    campaign.descriptionText = description
                }
                
                return campaign
            }
        } else {
            return nil
        }
        
        return nil
    }
    
    static func getCategoryLabelText(type: CampaignType) -> String {
        switch type {
        case .feature:
            return NSLocalizedString("dataHelper_feature_label", comment: "feature")
        case .proposal:
            return NSLocalizedString("dataHelper_proposal_label", comment: "proposal")
        case .complaint:
            return NSLocalizedString("dataHelper_complaint_label", comment: "complaint")
        case .call:
            return NSLocalizedString("dataHelper_call_label", comment: "call for action")
        case .change:
            return NSLocalizedString("dataHelper_change_label", comment: "change")
        case .topicAddOn:
            return NSLocalizedString("dataHelper_topic_addOn", comment: "topic addOn")
        case .all:
            return NSLocalizedString("dataHelper_proposal_label", comment: "proposal")
        }
    }
    
    static func getCampaignType(categoryString: String) -> CampaignCategory {
        
        switch categoryString {
        case "feature":
            return CampaignCategory(title: getCategoryLabelText(type: .feature), type: .feature)
        case "complaint":
            return CampaignCategory(title: getCategoryLabelText(type: .complaint), type: .complaint)
        case "call":
            return CampaignCategory(title: getCategoryLabelText(type: .call), type: .call)
        case "change":
            return CampaignCategory(title: getCategoryLabelText(type: .change), type: .change)
        case "topicAddOn":
            return CampaignCategory(title: getCategoryLabelText(type: .topicAddOn), type: .topicAddOn)
        default:
            return CampaignCategory(title: getCategoryLabelText(type: .proposal), type: .proposal)
        }
    }
}
