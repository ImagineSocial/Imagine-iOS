//
//  MeldeAgreeViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase
import FirebaseAuth

class MeldeAgreeViewController: UIViewController {

    var reportCategory = ""
    var choosenReportOption = ""
    var post = Post()
    let db = Firestore.firestore()
    
    @IBOutlet weak var MeldegrundLabel: UILabel!
    @IBOutlet weak var HinweisTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        displayNoticeAndWarning()
        
        print(post.title)
    }
    
    func displayNoticeAndWarning() {
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlineAttributedString = NSAttributedString(string:  "Der Grund für dein Melden: \(choosenReportOption)", attributes: underlineAttribute)
        MeldegrundLabel.attributedText = underlineAttributedString
        
        if reportCategory == "Optisch markieren" {
            HinweisTextLabel.text = "Deine Mituser überprüfen nun ob der Post markiert werden muss. Wir wollen dafür sorgen, dass wir durch ein transparentes Internet surfen. Bitte missbrauche diese Features nicht, sonst müssen wir deinen Trust-Rang heruntersetzen. Mehr Infos zu dem Meldesystem findest du im Info-Bereich.\nVielen Dank für deine Mithilfe!"
        } else if reportCategory == "Schlechte Absicht" {
            HinweisTextLabel.text = "Deine Mituser überprüfen nun ob der Post wegen schlechter Absichten entfernt werden muss. Wir wollen dafür sorgen, dass wir durch ein transparentes Internet surfen. Bitte missbrauche diese Features nicht, sonst müssen wir deinen Trust-Rang heruntersetzen. Mehr Infos zu dem Meldesystem findest du im Info-Bereich.\nVielen Dank für deine Mithilfe!"
            
        } else if reportCategory == "Lüge/Täuschung" {
            HinweisTextLabel.text = "Deine Mituser überprüfen nun ob der Post wegen Lüge oder Täuschung entfernt werden muss. Wir wollen dafür sorgen, dass wir durch ein transparentes Internet surfen. Bitte missbrauche diese Features nicht, sonst müssen wir deinen Trust-Rang heruntersetzen. Mehr Infos zu dem Meldesystem findest du im Info-Bereich.\nVielen Dank für deine Mithilfe!"
            
        } else if reportCategory == "Inhalt" {
            HinweisTextLabel.text = "Deine Mituser überprüfen nun ob der Post wegen unpassendem Inhalt entfernt werden muss. Wir wollen dafür sorgen, dass wir durch ein transparentes Internet surfen. Bitte missbrauche diese Features nicht, sonst müssen wir deinen Trust-Rang heruntersetzen. Mehr Infos zu dem Meldesystem findest du im Info-Bereich.\nVielen Dank für deine Mithilfe!"
        }
    }
    
    func saveReportOption() {
        // Erstmal nur optische Auswahl
        var reportOptionForDatabase = String()
        
        switch choosenReportOption {
        case "Meinung, kein Fakt":
            reportOptionForDatabase = "opinion"
        case "Sensationalismus":
            reportOptionForDatabase = "sensationalism"
        case "Circlejerk":
            reportOptionForDatabase = "circlejerk"
        case "Angeberisch":
            reportOptionForDatabase = "pretentious"
        case "Bildbearbeitung":
            reportOptionForDatabase = "edited"
        case "Schwarz-Weiß-Denken":
            reportOptionForDatabase = "ignorant"
        default:
            reportOptionForDatabase = "normal"
        }
        
        let postRef = db.collection("Posts")
        postRef.document(post.documentID).updateData(["report": reportOptionForDatabase]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
                
            }
        }
        
    }
    
    func saveReport() {
        let ref = db.collection("Reports").document()
        if let user = Auth.auth().currentUser {
            let data: [String:Any] = ["category": reportCategory, "reason": choosenReportOption, "reportingUser": user.uid, "reported post":post.documentID]
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Successfully saved")
                    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        saveReportOption()
        saveReport()
    }
    
    
}
