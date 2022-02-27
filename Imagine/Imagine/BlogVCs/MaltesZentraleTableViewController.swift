//
//  MaltesZentraleTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class MaltesZentraleTableViewController: UITableViewController {

    var mitteilungen = [Mitteilung]()
    let db = FirestoreRequest.shared.db
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getNotifications()
        getBugs()
        getReports()
    }
    
    func getBugs() {
        let ref = db.collection("Feedback").document("bugs").collection("bugs")
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        let data = document.data()
                        
                        let mitteilung = Mitteilung()
                        
                        if let type = data["bugType"] as? String, let problem =  data["problem"] as? String {
                            mitteilung.body = problem
                            mitteilung.header = type
                            
                            self.mitteilungen.append(mitteilung)
                            
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func getReports() {
        let ref = db.collection("Reports")
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {                
                if let snap = snap {
                    if snap.documents.count == 0 {
                        let mitteilung = Mitteilung()
                        mitteilung.header = "Keine Reports Chef!"
                        
                        self.mitteilungen.append(mitteilung)
                        self.tableView.reloadData()
                    }
                    for document in snap.documents {
                        let data = document.data()
                        
                        let mitteilung = Mitteilung()
                        
                        if let category = data["category"] as? String, let reason =  data["reason"] as? String {
                            mitteilung.body = reason
                            mitteilung.header = category
                            
                            self.mitteilungen.append(mitteilung)
                            
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    print("Keine Reports")
                }
            }
        }
    }
    
    func getNotifications() {
        let ref = db.collection("Users").document("CZOcL3VIwMemWwEfutKXGAfdlLy1").collection("notifications")
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        let data = document.data()
                        
                        let mitteilung = Mitteilung()
                        if let message = data["message"] as? String {
                            mitteilung.body = message
                        } else {
                            if let title = data["title"] as? String {
                                mitteilung.body = title
                            }
                        }
                        if let type = data["type"] as? String {
                            mitteilung.header = type
                        }
                        self.mitteilungen.append(mitteilung)
                        
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mitteilungen.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MaltesZentralenCell", for: indexPath) as? ZentralCell {

            let mitteilung = mitteilungen[indexPath.row]
            
            cell.headerLabel.text = mitteilung.header
            cell.bodyLabel.text = mitteilung.body
            
            return cell
        }
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

class Mitteilung {
    var header: String = ""
    var body: String = ""
}

class ZentralCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var bodyLabel: UILabel!
    
}
