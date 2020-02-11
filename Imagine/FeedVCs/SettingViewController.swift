//
//  SettingViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SettingViewController: UIViewController {

    @IBOutlet weak var cookieSwitch: UISwitch!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var deleteAccountButton: DesignableButton!
    @IBOutlet weak var notificationLabel: UILabel!
    
    let defaults = UserDefaults.standard
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if defaults.bool(forKey: "acceptedCookies") {
            cookieSwitch.isOn = true
        } else {
            cookieSwitch.isOn = false
        }
        
        if defaults.bool(forKey: "allowNotifications") {
            notificationSwitch.isOn = true
        } else {
            notificationSwitch.isOn = false
        }

        if let _ = Auth.auth().currentUser {
            
        } else {
            notificationSwitch.isEnabled = false
            notificationLabel.alpha = 0.7
            deleteAccountButton.alpha = 0.7
            deleteAccountButton.isEnabled = false
        }

    }
    
    @IBAction func cookieSwitchChanged(_ sender: Any) {
        if cookieSwitch.isOn {
            Analytics.setAnalyticsCollectionEnabled(true)
            defaults.set(true, forKey: "acceptedCookies")
            print("Allow Analytics")
        } else {
            defaults.set(false, forKey: "acceptedCookies")
            Analytics.setAnalyticsCollectionEnabled(false)
        }
    }
    
    @IBAction func notificationSwitchChanged(_ sender: Any) {
        if notificationSwitch.isOn {
            
            let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
            if !isRegisteredForRemoteNotifications {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
            
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error)")
                } else if let result = result {
                    self.defaults.set(true, forKey: "allowNotifications")
                    HandyHelper().saveFCMToken(token: result.token)
    
                    self.alert(message: "Push Benachrichtigungen aktiviert!")
                }
            }
            
            
        } else {
            if let user = Auth.auth().currentUser {
                let userRef = db.collection("Users").document(user.uid)
                
                userRef.updateData([
                    "fcmToken": FieldValue.delete(),
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err.localizedDescription)")
                    } else {
                        self.defaults.set(false, forKey: "allowNotifications")
                        print("Document successfully updated")
                    }
                }
            
//                userRef.setData(["fcmToken":token], mergeFields: ["fcmToken"])
            }
        }
    }
    
    @IBAction func deleteAccountTapped(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
            let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
            let notificationData: [String: Any] = ["type": "message", "message": "Jemand möchte seinen Account löschen", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "UserID": user.uid]
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.alert(message: "Dein Account wird innerhalb von 48h gelöscht. Du kannst dich jetzt ausloggen, wir machen den Rest.")
                    print("Successfully set notification")
                }
            }
        }
    }
    
    
    @IBAction func dataControlTapped(_ sender: Any) {
        
        if let url = URL(string: "https://donmalte.github.io") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func eulaTapped(_ sender: Any) {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }

}
