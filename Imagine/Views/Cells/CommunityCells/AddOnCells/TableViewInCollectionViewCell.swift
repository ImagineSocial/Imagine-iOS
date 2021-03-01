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
    let companyReuseIdentifier = "SmallCompanyTableViewCell"
    let jobOfferReuseIdentifier = "SupportTheCommunityCell"
    let voteCellIdentifier = "VoteCell"
    let addOnHeaderIdentifier = "InfoHeaderAddOnCell"
    
    var isEverySecondCell = false       // Change Design on every second Cell
    
    var delegate: TableViewInCollectionViewCellDelegate?
    
    let cornerRadius: CGFloat = 8
    
    override func awakeFromNib() {
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorStyle = .none
        
        tableView.register(UINib(nibName: "SmallCompanyTableViewCell", bundle: nil), forCellReuseIdentifier: companyReuseIdentifier)
        tableView.register(UINib(nibName: "JobOfferCell", bundle: nil), forCellReuseIdentifier: jobOfferReuseIdentifier)
        tableView.register(UINib(nibName: "VoteCell", bundle: nil), forCellReuseIdentifier: voteCellIdentifier)
        tableView.register(UINib(nibName: "InfoHeaderAddOnCell", bundle: nil), forCellReuseIdentifier: addOnHeaderIdentifier)
        
    }
    
    override func prepareForReuse() {
        isEverySecondCell = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layer = contentView.layer
        layer.cornerRadius = cornerRadius
        containerView.layer.cornerRadius = cornerRadius
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.label.cgColor
        } else {
            layer.shadowColor = UIColor.black.cgColor
        }
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
        
        let rect = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
    }
    
}

extension TableViewInCollectionViewCell: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        if let companys = items as? [Company] {
//            let company = companys[indexPath.row]
//
//            if let cell = tableView.dequeueReusableCell(withIdentifier: companyReuseIdentifier) as? SmallCompanyTableViewCell {
//                if isEverySecondCell {
//
//                    if #available(iOS 13.0, *) {
//                        cell.contentView.backgroundColor = .secondarySystemBackground
//                    } else {
//                        cell.contentView.backgroundColor = .ios12secondarySystemBackground
//                    }
//                } else {
//                    let layer = cell.contentView.layer
//
//                    if #available(iOS 13.0, *) {
//                        layer.borderColor = UIColor.secondarySystemBackground.cgColor
//                    } else {
//                        layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
//                    }
//                    layer.borderWidth = 1
//                    layer.cornerRadius = 5
//                }
//                cell.company = company
//                return cell
//            }
//        } else
        if let jobOffer = items as? [JobOffer] {
            if let cell = tableView.dequeueReusableCell(withIdentifier: jobOfferReuseIdentifier) as? JobOfferCell {
                
                if isEverySecondCell {
                
                    if #available(iOS 13.0, *) {
                        cell.contentView.backgroundColor = .secondarySystemBackground
                    } else {
                        cell.contentView.backgroundColor = .ios12secondarySystemBackground
                    }
                } else {
                    let layer = cell.contentView.layer
                    
                    if #available(iOS 13.0, *) {
                        layer.borderColor = UIColor.secondarySystemBackground.cgColor
                    } else {
                        layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
                    }
                    
                }
                cell.jobOffer = jobOffer[indexPath.row]
                cell.needInsets = false
                
                return cell
            }
        } else if let vote = items as? [Vote] {
            if let cell = tableView.dequeueReusableCell(withIdentifier: voteCellIdentifier) as? VoteCell {
                
                if isEverySecondCell {
                
                    if #available(iOS 13.0, *) {
                        cell.contentView.backgroundColor = .secondarySystemBackground
                    } else {
                        cell.contentView.backgroundColor = .ios12secondarySystemBackground
                    }
                    cell.contentView.layer.cornerRadius = 5
                } else {
                    let layer = cell.contentView.layer
                    
                    if #available(iOS 13.0, *) {
                        layer.borderColor = UIColor.secondarySystemBackground.cgColor
                    } else {
                        layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
                    }
                    layer.borderWidth = 1
                    layer.cornerRadius = 5
                }
                
                cell.needInsets = false
                cell.vote = vote[indexPath.row]
                
                return cell
            }
        } else if let info = items as? [AddOn] {
//            if let cell = tableView.dequeueReusableCell(withIdentifier: addOnHeaderIdentifier, for: indexPath) as? InfoHeaderAddOnCell {
//                
////                if info.count != 0 {
////                    if let header = info[0].addOnInfoHeader {
////                        cell.addOnInfo = header
////                    }
////                }
//                
//                return cell
//            }
        }
        
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: false)
        delegate?.itemTapped(item: item)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let _ = items as? [Company] {
//            return 50
//        } else {
            return tableView.frame.height
//        }
    }
    
    
}
