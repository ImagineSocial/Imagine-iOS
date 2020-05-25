//
//  NewAddOnTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import EasyTipView
import Firebase

class NewAddOnTableViewController: UITableViewController {
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var selectedAddOnTypeLabel: UILabel!
    @IBOutlet weak var didSelectAddOnImageView: UIImageView!
    
    var optionalInformations = [OptionalInformation]()
    var fact: Fact?
    var selectedAddOnStyle: OptionalInformationStyle?
    
    let addOnStoreCellIdentifier = "AddOnStoreImageTableViewCell"
    let addOnHeaderIdentifier = "AddOnHeaderView"
    
    var tipView: EasyTipView?
    
    var delegate: NewFactDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = fact else {
            print("No Fact")
            navigationController?.popViewController(animated: false)
            return
        }

        tableView.register(UINib(nibName: "AddOnStoreImageTableViewCell", bundle: nil), forCellReuseIdentifier: addOnStoreCellIdentifier)
        tableView.register(UINib(nibName: "AddOnHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: addOnHeaderIdentifier)
        tableView.separatorColor = .clear
        
        
        self.doneBarButtonItem.isEnabled = false
        self.doneBarButtonItem.tintColor = UIColor.blue.withAlphaComponent(0.5)
        
        let header = OptionalInformation(newAddOnStyle: .header)
        let infoAll = OptionalInformation(newAddOnStyle: .all)
        let singleTopic = OptionalInformation(newAddOnStyle: .singleTopic)
        
        optionalInformations.append(contentsOf: [header, infoAll, singleTopic])
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
                case .header:
                    cell.exampleImageView.image = UIImage(named: "AddOnHeaderExample")
                case .singleTopic:
                    cell.exampleImageView.image = UIImage(named: "AddOnSingleTopicExample")
                default:
                    cell.exampleImageView.image = UIImage(named: "AddOnCollectionExample")
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
            let info = optionalInformations[indexPath.section]
            
            switch info.style {
            case .singleTopic:
                return 350
            case .header:
                return 225
            default:
                return 300
            }
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
            case .header:
                self.selectedAddOnTypeLabel.text = "AddOn Header"
            case .all:
                self.selectedAddOnTypeLabel.text = "Post & Themen Kollektion"
            case .justPosts:
                self.selectedAddOnTypeLabel.text = "Collection of just Posts"
            case .justTopics:
                self.selectedAddOnTypeLabel.text = "Collection of just Topics"
            case .singleTopic:
                self.selectedAddOnTypeLabel.text = "Präsentation eines Themas"
            }
            
            
            tableView.setContentOffset(.zero, animated:true)
        } else {
            performSegue(withIdentifier: "toTrippyVCSegue", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewAddOnSegue" {
            if let navVC = segue.destination as? UINavigationController {
                if let vc = navVC.topViewController as? NewFactViewController {
                    if let style = sender as? OptionalInformationStyle {
                        if let fact = fact {
                            if style == .header {
                                vc.new = .addOnHeader
                            } else if style == .singleTopic {
                                vc.new = .singleTopicAddOn
                            } else {
                                vc.new = .addOn
                            }
                            vc.fact = fact
                            vc.delegate = self
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if let style = self.selectedAddOnStyle {
                performSegue(withIdentifier: "toNewAddOnSegue", sender: style)
            }
        }
    }
    
}

extension NewAddOnTableViewController: NewFactDelegate, AddOnHeaderDelegate {
    func thanksTapped(info: OptionalInformation) {
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
        if #available(iOS 13.0, *) {
            contentView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            contentView.layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
        }
    
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
