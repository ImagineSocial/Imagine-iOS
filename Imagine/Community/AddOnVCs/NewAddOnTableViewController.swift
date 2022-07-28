//
//  NewAddOnTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import EasyTipView
import FirebaseFirestore

class NewAddOnTableViewController: UITableViewController {
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var selectedAddOnTypeLabel: UILabel!
    @IBOutlet weak var didSelectAddOnImageView: UIImageView!
    
    var optionalInformations = [AddOn]()
    var community: Community?
    var selectedAddOnStyle: AddOnStyle?
    
    let addOnStoreCellIdentifier = "AddOnStoreImageTableViewCell"
    let addOnHeaderIdentifier = "AddOnHeaderView"
    
    var tipView: EasyTipView?
    let db = FirestoreRequest.shared.db
    
    weak var delegate: NewFactDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = community else {
            print("No Fact")
            navigationController?.popViewController(animated: false)
            return
        }

        tableView.register(UINib(nibName: "AddOnStoreImageTableViewCell", bundle: nil), forCellReuseIdentifier: addOnStoreCellIdentifier)
        tableView.register(UINib(nibName: "AddOnHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: addOnHeaderIdentifier)
        tableView.separatorColor = .clear
        
        
        self.doneBarButtonItem.isEnabled = false
        self.doneBarButtonItem.tintColor = UIColor.blue.withAlphaComponent(0.5)
        
        let infoAll = AddOn(style: .collection, OP: "", documentID: "", fact: Community(), headerTitle: NSLocalizedString("new_addOn_collection_header", comment: "new collection text"), description: Constants.texts.AddOns.collectionText, singleTopic: nil)
        let singleTopic = AddOn(style: .singleTopic, OP: "", documentID: "", fact: Community(), headerTitle: NSLocalizedString("new_addOn_singleTopic_header", comment: "new singleTopicText"), description: Constants.texts.AddOns.singleTopicText, singleTopic: nil)
        let QandA = AddOn(style: .QandA, OP: "", documentID: "", fact: Community(), description: Constants.texts.AddOns.QandAText)
        let youTubePlaylist = AddOn(style: .collectionWithYTPlaylist, OP: "", documentID: "", fact: Community(), headerTitle: NSLocalizedString("new_addOn_youtube_playlist_header", comment: "new collection text"), description: NSLocalizedString("new_addOn_youtube_playlist_description", comment: ""), singleTopic: nil)
        let playlistAddOn = AddOn(style: .playlist, OP: "", documentID: "", fact: Community(), headerTitle: NSLocalizedString("new_addOn_playlist_header", comment: "create playlist"), description: NSLocalizedString("new_addOn_playlist_description", comment: "whats up"), singleTopic: nil)
        
        optionalInformations.append(contentsOf: [infoAll, singleTopic, QandA, youTubePlaylist, playlistAddOn])
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
            self.tipView = nil
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return optionalInformations.count+1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if optionalInformations.count != indexPath.section {
            
            let info = optionalInformations[indexPath.section]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: addOnStoreCellIdentifier, for: indexPath) as? AddOnStoreImageTableViewCell {
                
                
                switch info.style {
                case .singleTopic:
                    cell.exampleImageView.image = UIImage(named: "AddOnSingleTopicExample")
                case .QandA:
                    cell.exampleImageView.image = UIImage(named: "AddOnQandAExample")
                case .collection:
                    cell.exampleImageView.image = UIImage(named: "AddOnCollectionExample")
                case .collectionWithYTPlaylist:
                    cell.exampleImageView.image = UIImage(named: "AddOnYouTubePlaylistExample")
                case .playlist:
                    cell.exampleImageView.image = UIImage(named: "AddOnPlaylistExample")
                }
                
                return cell
            }
        } else {
            let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
                
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
                
                }
                return cell
            }()

            cell.textLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
            cell.textLabel?.text = "I want more!"

            return cell
        }
        
        return UITableViewCell()
    }
   
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if optionalInformations.count != indexPath.section {
            return 350
        } else {
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if optionalInformations.count != section {
            
            let info = optionalInformations[section]
            
            if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: addOnHeaderIdentifier) as? AddOnHeaderView {
                
                headerView.info = info
                headerView.delegate = self
                headerView.thanksButton.isHidden = true
                
                return headerView
            }
        } //else {
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if optionalInformations.count != section {
            return UITableView.automaticDimension
        } else {
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if optionalInformations.count != indexPath.section {
            
            self.doneBarButtonItem.isEnabled = true
            self.doneBarButtonItem.tintColor = UIColor.blue.withAlphaComponent(1)
            self.didSelectAddOnImageView.image = UIImage(named: "greenTik")
            
            let info = optionalInformations[indexPath.section]
            
            self.selectedAddOnStyle = info.style
            
            switch info.style {
            case .collectionWithYTPlaylist:
                self.selectedAddOnTypeLabel.text = "YouTube Playlist AddOn"
            case .collection:
                self.selectedAddOnTypeLabel.text = NSLocalizedString("addOn_type_collection", comment: "adde a normal collection")
            case .singleTopic:
                self.selectedAddOnTypeLabel.text = NSLocalizedString("addOn_type_singleTopic", comment: "adde a singleTopic")
            case .QandA:
                self.selectedAddOnTypeLabel.text = NSLocalizedString("addOn_type_QandA", comment: "adde stuff")
            case .playlist:
                self.selectedAddOnTypeLabel.text = NSLocalizedString("addOn_type_playlist", comment: "adde playlist")
            }
            
            
            tableView.setContentOffset(.zero, animated:true)
        } else {
            performSegue(withIdentifier: "toTrippyVCSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewAddOnSegue" {
            if let navVC = segue.destination as? UINavigationController {
                if let vc = navVC.topViewController as? NewCommunityItemTableVC {
                    if let style = sender as? AddOnStyle {
                        if let community = community {
                            if style == .singleTopic {
                                vc.new = .singleTopicAddOn
                            } else if style == .collectionWithYTPlaylist {
                                vc.new = .addOnYouTubePlaylistDesign
                            } else {
                                vc.new = .addOn
                            }
                            vc.community = community
                            vc.delegate = self
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        guard let user = AuthenticationManager.shared.user, let community = community, let style = self.selectedAddOnStyle else {
            return
        }
        if style == .QandA {
            createNewQandAAddOn(user: user, community: community)
        } else {
            performSegue(withIdentifier: "toNewAddOnSegue", sender: style)
        }
    }
    
    func createNewQandAAddOn(user: User, community: Community) {
        
        guard let userID = user.uid, let communityID = community.id else {
            return
        }
        
        var collectionRef: CollectionReference!
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(communityID).collection("addOns").document()
        
        let data: [String:Any] = ["OP": userID, "type": "QandA", "popularity": 0]
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully created qAndA AddOn")
                self.finishedCreatingNewInstance(item: nil)
            }
        }
    }
    
}

extension NewAddOnTableViewController: NewFactDelegate, AddOnHeaderDelegate {
    
    func settingsTapped(section: Int) {
        print("Wont happen")
    }
    
    func thanksTapped(info: AddOn) {
        print("Coming Soon maybe")
    }
    
    func showPostsAsAFeed(section: Int) {
        print("Coming Soon")
    }
    
    func showDescription() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    func showAllPosts(documentID: String) {
        //nope
    }
    
    
    func finishedCreatingNewInstance(item: Any?) {
        delegate?.finishedCreatingNewInstance(item: item)
        self.navigationController?.popViewController(animated: true)
    }

}

class AddOnStoreImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exampleImageView: UIImageView!
    
    
    override func awakeFromNib() {
        
        //Cell UI
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
    
        contentView.clipsToBounds = true
        backgroundColor =  .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
}
