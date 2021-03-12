//
//  TableViewInCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol TableViewInCollectionViewCellDelegate {
    func itemTapped(item: Any)
}

class TableViewInCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    
    var items = [Any]()
    private let companyReuseIdentifier = "SmallCompanyTableViewCell"
    private let jobOfferReuseIdentifier = "SupportTheCommunityCell"
    private let voteCellIdentifier = "VoteCell"
    private let addOnHeaderIdentifier = "InfoHeaderAddOnCell"
    private let campaignCellIdentifier = "campaignCell"
    
    var isEverySecondCell = false       // Change Design on every second Cell
    
    var delegate: TableViewInCollectionViewCellDelegate?
    
    let cornerRadius: CGFloat = Constants.cellCornerRadius
    
    override func awakeFromNib() {
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorStyle = .none
        
        tableView.register(UINib(nibName: "SmallCompanyTableViewCell", bundle: nil), forCellReuseIdentifier: companyReuseIdentifier)
        tableView.register(UINib(nibName: "JobOfferCell", bundle: nil), forCellReuseIdentifier: jobOfferReuseIdentifier)
        tableView.register(UINib(nibName: "VoteCell", bundle: nil), forCellReuseIdentifier: voteCellIdentifier)
        tableView.register(UINib(nibName: "InfoHeaderAddOnCell", bundle: nil), forCellReuseIdentifier: addOnHeaderIdentifier)
        tableView.register(UINib(nibName: "CampaignCell", bundle: nil), forCellReuseIdentifier: campaignCellIdentifier)
    }
    
    override func prepareForReuse() {
        isEverySecondCell = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = cornerRadius
        
        contentView.setDefaultShadow()
    }
    
}

extension TableViewInCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let jobOffer = items as? [JobOffer] {
            if let cell = tableView.dequeueReusableCell(withIdentifier: jobOfferReuseIdentifier) as? JobOfferCell {
                
                cell.jobOffer = jobOffer[indexPath.row]
                cell.needInsets = false
                
                return cell
            }
        } else if let vote = items as? [Vote] {
            if let cell = tableView.dequeueReusableCell(withIdentifier: voteCellIdentifier) as? VoteCell {
                
                cell.needInsets = false
                cell.vote = vote[indexPath.row]
                
                return cell
            }
        } else if let campaigns = items as? [Campaign] {
            if let cell = tableView.dequeueReusableCell(withIdentifier: campaignCellIdentifier, for: indexPath) as? CampaignCell {
                let campaign = campaigns[indexPath.row]
                
                cell.campaign = campaign
                
                return cell
            }
        }
        
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: false)
        delegate?.itemTapped(item: item)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

            return tableView.frame.height
    }
    
    
}
