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
    @IBOutlet weak var languageSegmentedControl: UISegmentedControl!
    
    let defaults = UserDefaults.standard
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteAccountButton.layer.borderColor = UIColor.systemRed.cgColor
        deleteAccountButton.layer.borderWidth = 0.5
        deleteAccountButton.cornerRadius = 4
        
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

        let language = LanguageSelection().getLanguage()
        if language == .english {
            languageSegmentedControl.selectedSegmentIndex = 1
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
    
                    self.alert(message: NSLocalizedString("push_alert_message", comment: "got push notifications"))
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
        deleteAccountButton.isEnabled = false
        deleteAccountButton.alpha = 0.5
        
        if let user = Auth.auth().currentUser {
            let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
            let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
            let notificationData: [String: Any] = ["type": "message", "message": "Jemand möchte seinen Account löschen", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "UserID": user.uid]
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                    self.deleteAccountButton.isEnabled = true
                    self.deleteAccountButton.alpha =  1
                } else {
                    self.alert(message: NSLocalizedString("delete_account_alert_message", comment: "in the next 48h it will be deleted"))
                    print("Successfully set notification")
                }
            }
        }
    }
    
    @IBAction func languageSegmentedControlChanged(_ sender: Any) {
        let pre = Locale.preferredLanguages[0]
        
        if languageSegmentedControl.selectedSegmentIndex == 0 { //german
            if pre == "de" {
                defaults.removeObject(forKey: "languageSelection")
            } else {
                defaults.set("de", forKey: "languageSelection")
            }
        } else if languageSegmentedControl.selectedSegmentIndex == 1 {  //english
            if pre == "en" {
                defaults.removeObject(forKey: "languageSelection")
            } else {
                defaults.set("en", forKey: "languageSelection")
            }
        }
//        if let language = defaults.string(forKey: "languageSelection"){ }
    }
    
    @IBAction func dataControlTapped(_ sender: Any) {
        let language = LanguageSelection().getLanguage()
        if language == .german {
            if let url = URL(string: "https://www.imagine.social/datenschutzerklaerung-app") {
                UIApplication.shared.open(url)
            }
        } else {
            if let url = URL(string: "https://en.imagine.social/datenschutzerklaerung-app") {
                UIApplication.shared.open(url)
            }
        }
    }
    @IBAction func eulaTapped(_ sender: Any) {
        let language = LanguageSelection().getLanguage()
        if language == .german {
            if let url = URL(string: "https://www.imagine.social/eula") {
                UIApplication.shared.open(url)
            }
        } else {
            if let url = URL(string: "https://en.imagine.social/eula") {
                UIApplication.shared.open(url)
            }
        }
    }

}
