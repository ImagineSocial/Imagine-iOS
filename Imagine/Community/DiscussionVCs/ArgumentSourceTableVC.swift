//
//  SourceTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ArgumentSourceTableVC: UITableViewController {
    
    var argument: Argument?
    var community :Community?
    var sources = [Source]()
    
    let reuseIdentifier = "addCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.layer.cornerRadius = 1
        tableView.separatorStyle = .none
        
        tableView.register(AddFactCell.self, forCellReuseIdentifier: reuseIdentifier)
        print("SourceTableView loaded")
        getSources()
    }
    
    func getSources() {
        if let argument = argument, let community = community {
            DataRequest().getDeepestArgument(community: community, argumentID: argument.documentID, deepDataType: .sources) { (deepestData) in
                if let sources = deepestData as? [Source] {
                    self.sources = sources
                    self.tableView.reloadData()
                }
            }
        } else {
            print("No Argument or Fact")
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sources.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let source = sources[indexPath.row]
        
        if source.addMoreCell {
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? AddFactCell {
                
                
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "sourceCell", for: indexPath) as? sourceCell {
                
                cell.sourceLabel.text = source.title
                cell.upvoteLabel.text = "▲ 34"
                cell.downvoteLabel.text = "▼ 12"
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let source = sources[indexPath.row]
        if source.addMoreCell {
            if let _ = Auth.auth().currentUser {
                performSegue(withIdentifier: "toNewArgumentSegue", sender: nil)
            } else {
                self.notLoggedInAlert()
            }
        } else {
            performSegue(withIdentifier: "toSourceDetail", sender: source)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let source = sources[indexPath.row]
        
        if source.addMoreCell {
            return 50
        } else {
            return UITableView.automaticDimension
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewArgumentSegue" {
            if let nav = segue.destination as? UINavigationController {
                if let vc = nav.topViewController as? NewCommunityItemTableVC {
                    vc.community = self.community
                    vc.argument = self.argument
                    vc.new = .source
                    vc.delegate = self
                }
            }
        }
        
        if segue.identifier == "toSourceDetail" {
            if let vc = segue.destination as? ArgumentDetailVC {
                if let source = sender as? Source {
                    vc.source = source
                }
            }
        }
    }
}

extension ArgumentSourceTableVC: NewFactDelegate {
    func finishedCreatingNewInstance(item: Any?) {
        if let source = item as? Source {
            let count = self.sources.count
            
            self.sources.insert(source, at: count-1)
            self.tableView.reloadData()
        }
    }
}

class sourceCell: UITableViewCell {
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var downvoteLabel: UILabel!
    @IBOutlet weak var upvoteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        backgroundColor =  .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 0, left: 5, bottom: 3, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
}
