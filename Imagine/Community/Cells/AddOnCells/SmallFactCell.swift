//
//  WhyGuiltyCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class SmallFactCell: UICollectionViewCell {
    
//    @IBOutlet weak var factImageView: UIImageView!
//    @IBOutlet weak var factHeaderTitle: UILabel!
//    @IBOutlet weak var factHeaderDescriptionLabel: UILabel!
    @IBOutlet weak var topicView: DesignablePopUp!
    @IBOutlet weak var firstArgumentLabel: UILabel!
    @IBOutlet weak var secondArgumentLabel: UILabel!
    @IBOutlet weak var firstArgumentUpvoteCount: UILabel!
    @IBOutlet weak var secondArgumentUpvoteCount: UILabel!
    @IBOutlet weak var argumentStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var hairlineView: HairlineView!
    
    
    let db = FirestoreRequest.shared.db
    
    var postTitle: String? {
        didSet {
           if postTitle! == "gotcha" {
               titleLabelHeightConstraint.constant = 0
           } else {
               titleLabel.text = postTitle!
           }
            
        }
    }
    
    var community: Community? {
        didSet {
            guard let community = community else { return }
            
            self.getArguments(community: community)
            
            if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                factImageView.sd_setImage(with: url, completed: nil)
            }
            
            factHeaderTitle.text = community.title
            factHeaderDescriptionLabel.text = community.description
            self.factPostCountLabel.text = "Posts: \(community.postCount ?? 0)"
            self.factFollowerCountLabel.text = "Follower: \(community.followerCount ?? 0)"
        }
    }
    
    var communityID: String? {
        didSet {
            guard let communityID = communityID else {
                return
            }
            
            CommunityHelper.getCommunity(withID: communityID) { community in
                self.community = community
            }
        }
    }
    
    func setUI(displayOption: DisplayOption) {
        switch displayOption {
        case .topic:
            argumentStackView.isHidden = true
            hairlineView.isHidden = true
            
            topicView.addSubview(factHeaderTitle)
            factHeaderTitle.leadingAnchor.constraint(equalTo: topicView.leadingAnchor, constant: 5).isActive = true
            factHeaderTitle.trailingAnchor.constraint(equalTo: topicView.trailingAnchor, constant: -5).isActive = true
            factHeaderTitle.topAnchor.constraint(equalTo: topicView.topAnchor, constant:5).isActive = true
            factHeaderTitle.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            topicView.addSubview(factImageView)
            factImageView.leadingAnchor.constraint(equalTo: topicView.leadingAnchor, constant: 5).isActive = true
            factImageView.topAnchor.constraint(equalTo: factHeaderTitle.bottomAnchor, constant: 5).isActive = true
            
            factImageView.layer.borderWidth = 1
            factImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
            
            
            topicView.addSubview(factFollowerCountLabel)
            factFollowerCountLabel.leadingAnchor.constraint(equalTo: factImageView.trailingAnchor, constant: 10).isActive = true
            factFollowerCountLabel.trailingAnchor.constraint(equalTo: topicView.trailingAnchor, constant: -10).isActive = true
            factFollowerCountLabel.topAnchor.constraint(equalTo: factImageView.topAnchor, constant: 5).isActive = true
            factFollowerCountLabel.widthAnchor.constraint(equalToConstant: 65).isActive = true
            
            topicView.addSubview(factPostCountLabel)
            factPostCountLabel.leadingAnchor.constraint(equalTo: factImageView.trailingAnchor, constant: 10).isActive = true
            factPostCountLabel.trailingAnchor.constraint(equalTo: factPostCountLabel.trailingAnchor, constant: -10).isActive = true
            factPostCountLabel.topAnchor.constraint(equalTo: factFollowerCountLabel.bottomAnchor, constant: 10).isActive = true
            factPostCountLabel.widthAnchor.constraint(equalToConstant: 65).isActive = true
            
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.cornerRadius = 4
            view.backgroundColor = .secondarySystemBackground
            
            view.addSubview(factHeaderDescriptionLabel)
            factHeaderDescriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
            factHeaderDescriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
            factHeaderDescriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            factHeaderDescriptionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3).isActive = true
            
            topicView.addSubview(view)
            view.heightAnchor.constraint(equalToConstant: 50).isActive = true
            view.topAnchor.constraint(equalTo: factImageView.bottomAnchor, constant: -10).isActive = true
            view.leadingAnchor.constraint(equalTo: topicView.leadingAnchor, constant: 5).isActive = true
            view.trailingAnchor.constraint(equalTo: topicView.trailingAnchor, constant: -5).isActive = true
            view.bottomAnchor.constraint(equalTo: topicView.bottomAnchor, constant: -5).isActive = true
            
            
        case .discussion:
            topicView.addSubview(factImageView)
            factImageView.leadingAnchor.constraint(equalTo: topicView.leadingAnchor, constant: 2).isActive = true
            factImageView.topAnchor.constraint(equalTo: topicView.topAnchor, constant: 2).isActive = true
            factImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            factImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            topicView.addSubview(factHeaderTitle)
            factHeaderTitle.leadingAnchor.constraint(equalTo: factImageView.trailingAnchor, constant: 2).isActive = true
            factHeaderTitle.trailingAnchor.constraint(equalTo: topicView.trailingAnchor, constant: -2).isActive = true
            factHeaderTitle.topAnchor.constraint(equalTo: factImageView.topAnchor).isActive = true
            factHeaderTitle.heightAnchor.constraint(equalToConstant: 15).isActive = true
            
            topicView.addSubview(factHeaderDescriptionLabel)
            factHeaderDescriptionLabel.leadingAnchor.constraint(equalTo: factImageView.trailingAnchor, constant: 2).isActive = true
            factHeaderDescriptionLabel.trailingAnchor.constraint(equalTo: topicView.trailingAnchor, constant: -2).isActive = true
            factHeaderDescriptionLabel.topAnchor.constraint(equalTo: factHeaderTitle.bottomAnchor).isActive = true
            factHeaderDescriptionLabel.bottomAnchor.constraint(equalTo: factImageView.bottomAnchor).isActive = true
            
        }
    }
    
    func getArguments(community: Community) {
        guard let communityID = community.id else {
            return
        }
        
        let argumentReference = FirestoreCollectionReference(document: communityID, collection: "arguments")
        let proReference = FirestoreReference.collectionRef(.communities, collectionReferences: argumentReference, queries: FirestoreQuery(field: "proOrContra", equalTo: "pro"), FirestoreQuery(field: "upvotes", limit: 1))
        
        proReference.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
        let contraReference = FirestoreReference.collectionRef(.communities, collectionReferences: argumentReference, queries: FirestoreQuery(field: "proOrContra", equalTo: "contra"), FirestoreQuery(field: "upvotes", limit: 1))
        
        contraReference.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
    }
    
    func addArgumentFromSnap(snapshot: QuerySnapshot) {
        for document in snapshot.documents {
            let data = document.data()
            
            guard let title = data["title"] as? String, let proOrContra = data["proOrContra"] as? String, let upvotes = data["upvotes"] as? Int, let downvotes = data["downvotes"] as? Int else {
                return
            }
            if proOrContra == "pro" {
                firstArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                firstArgumentUpvoteCount.text = String(upvotesCompined)
            } else {
                secondArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                secondArgumentUpvoteCount.text = String(upvotesCompined)
            }
            
        }
    }
    
    let factImageView : UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "default-community")
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    
    let factHeaderTitle: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        label.minimumScaleFactor = 0.6
        
        return label
    }()
    
    let factHeaderDescriptionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.75
        
        return label
    }()
    
    let factFollowerCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 11)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    let factPostCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 11)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    override func awakeFromNib() {
        
        contentView.backgroundColor = .secondarySystemBackground
        
        layoutIfNeeded()
        
        contentView.layer.cornerRadius = 6
        factImageView.layer.cornerRadius = 4
        backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        titleLabelHeightConstraint.constant = 50
        argumentStackView.isHidden = false
        hairlineView.isHidden = false
    }
    
}
