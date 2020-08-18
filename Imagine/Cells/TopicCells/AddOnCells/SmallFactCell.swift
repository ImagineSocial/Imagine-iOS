//
//  WhyGuiltyCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

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
    
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var postTitle: String? {
        didSet {
           if postTitle! == "gotcha" {
               titleLabelHeightConstraint.constant = 0
           } else {
               titleLabel.text = postTitle!
           }
            
        }
    }
    
    var fact: Fact? {
        didSet {
            guard let fact = fact else { return }
            
            self.getArguments(documentID: fact.documentID)
            
            if let url = URL(string: fact.imageURL) {
                factImageView.sd_setImage(with: url, completed: nil)
            } else {
                factImageView.image = UIImage(named: "FactStamp")
            }
            factHeaderTitle.text = fact.title
            factHeaderDescriptionLabel.text = fact.description
                     
            fact.getFollowerCount { (count) in
                self.factFollowerCountLabel.text = "Follower: \(count)"
            }
            
            fact.getPostCount { (count) in
                self.factPostCountLabel.text = "Posts: \(count)"
            }
        }
    }
    
    var factID: String? {
        didSet {
            if let factID = factID {
                DispatchQueue.global(qos: .default).async {
                    self.dataHelper.loadFact(factID: factID) { (fact) in
                        if let fact = fact {
                            DispatchQueue.main.async {
                                self.fact = fact
                            }
                        }
                    }
                }
            } else {
                return
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
            if #available(iOS 13.0, *) {
                factImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                factImageView.layer.borderColor = UIColor.lightGray.cgColor
            }
            
            
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
            if #available(iOS 13.0, *) {
                view.backgroundColor = .secondarySystemBackground
            } else {
                view.backgroundColor = .ios12secondarySystemBackground
            }
            
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
            
            
        case .fact:
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
    
    func getArguments(documentID: String) {
        if documentID == "" { return }
        
        let ref = db.collection("Facts").document(documentID).collection("arguments")
        
        let proRef = ref.whereField("proOrContra", isEqualTo: "pro").order(by: "upvotes", descending: true).limit(to: 1)
        proRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
        let contraRef = ref.whereField("proOrContra", isEqualTo: "contra").order(by: "upvotes", descending: true).limit(to: 1)
        contraRef.getDocuments { (snap, err) in
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
        imageView.image = UIImage(named: "FactStamp")
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
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.75
        
        return label
    }()
    
    let factFollowerCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 11)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        
        return label
    }()
    
    let factPostCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 11)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .lightGray
        }
        
        return label
    }()
    
    override func awakeFromNib() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .secondarySystemBackground
        } else {
            contentView.backgroundColor = .ios12secondarySystemBackground
        }
        
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
