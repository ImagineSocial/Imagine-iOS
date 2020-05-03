//
//  NewAddOnTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class NewAddOnTableViewController: UITableViewController {
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var selectedAddOnTypeLabel: UILabel!
    @IBOutlet weak var didSelectAddOnImageView: UIImageView!
    
    var optionalInformations = [OptionalInformation]()
    var fact: Fact?
    var selectedAddOnStyle: OptionalInformationType?
    
    let collectionViewCellIdentifier = "CollectionViewInTableViewCell"
    let infoHeaderCellIdentifier = "InfoHeaderAddOnCell"
    
    var delegate: NewFactDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let _ = fact else {
            print("No Fact")
            navigationController?.popViewController(animated: false)
            return
        }

        tableView.register(UINib(nibName: "CollectionViewInTableViewCell", bundle: nil), forCellReuseIdentifier: collectionViewCellIdentifier)
        tableView.register(UINib(nibName: "InfoHeaderAddOnCell", bundle: nil), forCellReuseIdentifier: infoHeaderCellIdentifier)
        tableView.separatorColor = .clear
        
        
        self.doneBarButtonItem.isEnabled = false
        self.doneBarButtonItem.tintColor = UIColor.blue.withAlphaComponent(0.5)
        
        let header = OptionalInformation(newAddOnStyle: .header)
        let infoAll = OptionalInformation(newAddOnStyle: .all)
//        let infoPosts = OptionalInformation(newAddOnStyle: .justPosts)
//        let infoTopics = OptionalInformation(newAddOnStyle: .justTopics)
        
        optionalInformations.append(contentsOf: [header, infoAll])
        tableView.reloadData()
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
            
            if let addOnHeader = info.addOnInfoHeader {
                if let cell = tableView.dequeueReusableCell(withIdentifier: infoHeaderCellIdentifier, for: indexPath) as? InfoHeaderAddOnCell {
                    
                    cell.addOnInfo = addOnHeader
                    cell.selectionStyle = .none
                    
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: collectionViewCellIdentifier, for: indexPath) as? CollectionViewInTableViewCell {
                    
                    cell.info = info
                    cell.collectionView.isUserInteractionEnabled = false
                    cell.isAddOnStoreCell = true
                    
                    return cell
                }
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
            
            if let _ = info.addOnInfoHeader {
                return UITableView.automaticDimension
            } else {
                return 250
            }
        } else {
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if optionalInformations.count != section {
            
            let headerView = AddOnHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
            
            let info = optionalInformations[section]
            headerView.initHeader(noOptionalInformation: false, info: info)
            headerView.descriptionButton.isHidden = true
            //            headerView.delegate = self
            //
            return headerView
            //        }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if optionalInformations.count != section {
            return 60
        } else {
            return 0
        }
//        return UITableView.automaticDimension
        
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
            
            if let style = info.style {
                self.selectedAddOnStyle = style
                
                switch style {
                case .header:
                    self.selectedAddOnTypeLabel.text = "AddOn Header"
                case .all:
                    self.selectedAddOnTypeLabel.text = "Post & Themen Kollektion"
                case .justPosts:
                    self.selectedAddOnTypeLabel.text = "Collection of just Posts"
                case .justTopics:
                    self.selectedAddOnTypeLabel.text = "Collection of just Topics"
                }
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
                    if let style = sender as? OptionalInformationType {
                        if let fact = fact {
                            if style == .header {
                                vc.new = .addOnHeader
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
        if let style = self.selectedAddOnStyle {
            performSegue(withIdentifier: "toNewAddOnSegue", sender: style)
        }
    }
    
}

extension NewAddOnTableViewController: NewFactDelegate {
    
    func finishedCreatingNewInstance(item: Any?) {
        delegate?.finishedCreatingNewInstance(item: item)
        self.navigationController?.popViewController(animated: true)
    }

}
