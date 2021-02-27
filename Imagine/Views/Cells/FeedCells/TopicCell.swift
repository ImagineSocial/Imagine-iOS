//
//  TopicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol TopTopicCellDelegate {
    func owenTapped()
    func factOfTheWeekTapped(fact:Fact)
}

class TopicCell: UITableViewCell {
    @IBOutlet weak var weeklyTopicView: UIView!
    @IBOutlet weak var topLevelFactImageView: UIImageView!
    @IBOutlet weak var topLevelFactLabel: UILabel!
    @IBOutlet weak var midLevelFactImageView: UIImageView!
    @IBOutlet weak var midLevelFactLabel: UILabel!
    @IBOutlet weak var lowerLevelFactImage: UIImageView!
    @IBOutlet weak var lowerLevelFactLabel: UILabel!
    @IBOutlet weak var owenButton: UIButton!
    @IBOutlet weak var owenPortraitImageView: UIImageView!
    @IBOutlet weak var owenHeight: NSLayoutConstraint!
    @IBOutlet weak var owenWidth: NSLayoutConstraint!
    @IBOutlet weak var owenLeading: NSLayoutConstraint!
    @IBOutlet weak var stackBackgroundView: UIView!
    @IBOutlet weak var textOfTheWeekLabel: UILabel!
    
    let db = Firestore.firestore()
    private let cornerRadius: CGFloat = 6
    
    var delegate: TopTopicCellDelegate?
    var facts = [Fact]()
    var textOfTheWeek: String?
        
    override func awakeFromNib() {
        selectionStyle = .none
        
        getData()
        
        weeklyTopicView.layer.cornerRadius = cornerRadius
        stackBackgroundView.layer.cornerRadius = cornerRadius
        
        let imageViews = [topLevelFactImageView!, midLevelFactImageView!, lowerLevelFactImage!]
        
        for imageView in imageViews {
            imageView.layer.borderWidth = 1
            if #available(iOS 13.0, *) {
                imageView.layer.borderColor = UIColor.quaternarySystemFill.cgColor
            } else {
                imageView.layer.borderColor = UIColor(red: 116.0, green: 116.0, blue: 128.0, alpha: 0.08).cgColor
            }
            imageView.layer.cornerRadius = 3
        }
        
        //DesignStuff
        for view in [weeklyTopicView, stackBackgroundView] {
            let layer = view!.layer
            if #available(iOS 13.0, *) {
                layer.shadowColor = UIColor.label.cgColor
            } else {
                layer.shadowColor = UIColor.black.cgColor
            }
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowRadius = 3
            layer.shadowOpacity = 0.4
        }
    }
    
    func getData() {
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("topTopicData")
        } else {
            collectionRef = db.collection("TopTopicData")
        }
        let ref = collectionRef.document("TopTopicData")
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                
                if let snapshot = snap {
                    if let data = snapshot.data() {
                        
                        if let textOfTheWeek = data["textOfTheWeek"] as? String {
                            self.textOfTheWeekLabel.text = textOfTheWeek
                        } else {
                            self.textOfTheWeekLabel.text = Constants.strings.textOfTheWeek
                        }
                        if let factIDs = data["linkedFactIDs"] as? [String] {
                            self.loadFacts(language: language, factIDs: factIDs) { (facts) in
                                self.showFacts(facts: facts)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showFacts(facts: [Fact]) {
        
        var index = 0
        
        for fact in facts {
            
            switch index {
            case 0:
                if let url = URL(string: fact.imageURL) {
                    topLevelFactImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                }
                topLevelFactLabel.text = fact.title
            case 1:
                if let url = URL(string: fact.imageURL) {
                    midLevelFactImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                }
                midLevelFactLabel.text = fact.title
            default:
                if let url = URL(string: fact.imageURL) {
                    lowerLevelFactImage.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                }
                lowerLevelFactLabel.text = fact.title
            }
            
            index+=1
        }
    }
    
    func loadFacts(language: Language, factIDs: [String], completion: @escaping ([Fact]) -> Void) {
        
        for factID in factIDs {
            var collectionRef: CollectionReference!
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(factID)
            ref.getDocument { (doc, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let document = doc {
                        if let data = document.data() {
                            guard let name = data["name"] as? String else {
                                return
                            }
                            let fact = Fact()
                            
                            if let displayString = data["displayOption"] as? String {
                                if displayString == "topic" {
                                    fact.displayOption = .topic
                                } else {
                                    fact.displayOption = .fact
                                }
                            }
                            fact.title = name
                            fact.documentID = document.documentID
                            if let url = data["imageURL"] as? String {
                                fact.imageURL = url
                            }
                            if let description = data["description"] as? String {
                                fact.description = description
                            }
                            if let language = data["language"] as? String {
                                if language == "en" {
                                    fact.language = .english
                                }
                            }
                            fact.fetchComplete = true
                            
                            self.facts.append(fact)

                            if self.facts.count == factIDs.count {
                                completion(self.facts)
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    override func layoutSubviews() {
            super.layoutSubviews()
            
            let margins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            contentView.frame = contentView.frame.inset(by: margins)
    }
    
    @IBAction func owenButtonTapped(_ sender: Any) {
        owenWidth.constant = 600
        owenHeight.constant = 600
        owenLeading.constant = -200
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.delegate?.owenTapped()
        }
        
        UIView.animate(withDuration: 0.7, delay: 0, options: .curveLinear, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            
            self.owenWidth.constant = 30
            self.owenHeight.constant = 30
            self.owenLeading.constant = 10

        }
    }
    
    @IBAction func topStackViewTapped(_ sender: Any) {
        let topic = facts[0]
        self.topicTapped(topic: topic)
    }
    @IBAction func middleStackViewTapped(_ sender: Any) {
        let topic = facts[1]
        self.topicTapped(topic: topic)
    }
    @IBAction func lowerStackViewTapped(_ sender: Any) {
        let topic = facts[2]
        self.topicTapped(topic: topic)
    }
    
    func topicTapped(topic: Fact) {
        topic.getFollowStatus { (isFollowed) in
            if isFollowed {
                topic.beingFollowed = true
                self.delegate?.factOfTheWeekTapped(fact: topic)
            } else {
                self.delegate?.factOfTheWeekTapped(fact: topic)
            }
        }
    }
}
