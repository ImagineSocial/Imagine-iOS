//
//  AdventskalenderTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 20.11.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class Adventstag {
    var imageURL: String?
    var day: Int?
    var description : String?
    var solved = false
}

class AdventskalenderTableViewController: UITableViewController {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var adventstage = [Adventstag]()
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

    
        getDataForTheAdventskalender()
        
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "AdventstagCell", bundle: nil), forCellReuseIdentifier: "AdventstagCell")
        
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                print("Nicht bei Malte loggen")
            } else {
                Analytics.logEvent("Adventskalender", parameters: [:])
            }
        } else {
            Analytics.logEvent("FactDetailOpened", parameters: [:])
        }
    }
    
    func getDataForTheAdventskalender() {
        let adventRef = db.collection("Adventskalender").order(by: "day", descending: false)
        
        adventRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snapshot = snap {
                    for document in snapshot.documents {
                        let data = document.data()
                        
                        guard let day = data["day"] as? Int, let imageURL = data["imageURL"] as? String, let description = data["description"] as? String, let solved = data["solved"] as? Bool else {
                            continue
                        }
                        
                        let adventstag = Adventstag()
                        
                        adventstag.day = day
                        adventstag.description = description
                        adventstag.imageURL = imageURL
                        adventstag.solved = solved
                        
                        self.adventstage.append(adventstag)
                    }
                    // After every document is added
                    self.addRemainingDays()
                }
            }
        }
    }
    
    func addRemainingDays() {
        var days = self.adventstage.count
        
        while days<=23 {
            
            print("So viele Adventstage haben wir: \(self.adventstage.count)")
            
            let day = Adventstag()
            self.adventstage.append(day)
            days+=1
        }
        
        print("Reload TableView")
        self.tableView.reloadData()
        
//        let actualDay = Date().day-1
//        
//        tableView.scrollToRow(at: IndexPath(row: actualDay, section: 0), at: .top, animated: true)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return adventstage.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tag = adventstage[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AdventstagCell", for: indexPath) as? AdventstagCell {

            cell.delegate = self
            
            cell.adventstag = tag
            let day = indexPath.row+1
            let dayString = "\(day). Dez"
            cell.dayLabel.text = dayString

            return cell
            
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        print("InfoButtonTapped")
        let adventskalenderIntro = "Vom 1. Dezember bis Heiligabend hast du jeden Tag die Chance auf ein kühles, erfrischendes passauer Bier!\n\nWir geben dir Hinweise mittels Bild und Text, den Rest erledigt dein Gedächtnis.\nDu erkennst den Spot auf dem Bild wieder? Dann mal schnell los, bevor es ein anderer gefunden hat.\n\nPostest du anschließend ein Bild mit deiner Beute, findest du dich hier wieder!"
        
        infoButton.showEasyTipView(text: adventskalenderIntro)
    }
    
}

extension AdventskalenderTableViewController: AdventsDelegate {
    func pictureTapped(image: UIImage) {
        let pinchVC = PinchToZoomViewController()
        pinchVC.image = image
        
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
}
