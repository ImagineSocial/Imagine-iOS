//
//  SourceTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SourceTableViewController: UITableViewController {
    
    var argument: Argument?
    var fact :Fact?
    var sources = [Source]()
    
    let reuseIdentifier = "addCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.layer.cornerRadius = 1
        tableView.backgroundColor = Constants.backgroundColorForTableViews
        tableView.separatorStyle = .none
        
        tableView.register(AddFactCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        getSources()
    }
    
    func getSources() {
        if let argument = argument, let fact = fact {
            DataHelper().getDeepestArgument(factID: fact.documentID, argumentID: argument.documentID, deepDataType: .sources) { (deepestData) in
                if let sources = deepestData as? [Source] {
                    print("Jommen welche an: \(sources)")
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
            return 60
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewArgumentSegue" {
            if let nav = segue.destination as? UINavigationController {
                if let vc = nav.topViewController as? NewFactViewController {
                    vc.fact = self.fact
                    vc.argument = self.argument
                    vc.new = .source
                }
            }
        }
        
        if segue.identifier == "toSourceDetail" {
            if let vc = segue.destination as? ArgumentDetailViewController {
                if let source = sender as? Source {
                    vc.source = source
                }
            }
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
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 5
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
