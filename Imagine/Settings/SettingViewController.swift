//
//  SettingViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseMessaging
import FirebaseFirestore

class SettingViewController: UIViewController {

    @IBOutlet weak var cookieSwitch: UISwitch!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var deleteAccountButton: DesignableButton!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var languageSegmentedControl: UISegmentedControl!
    
    let defaults = UserDefaults.standard
    let db = FirestoreRequest.shared.db
    
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

        if !AuthenticationManager.shared.isLoggedIn {
            notificationSwitch.isEnabled = false
            notificationLabel.alpha = 0.7
            deleteAccountButton.alpha = 0.7
            deleteAccountButton.isEnabled = false
        }

        if LanguageSelection.language == .en {
            languageSegmentedControl.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func cookieSwitchChanged(_ sender: Any) {
        if cookieSwitch.isOn {
            defaults.set(true, forKey: "acceptedCookies")
            print("Allow Analytics")
        } else {
            defaults.set(false, forKey: "acceptedCookies")
        }
    }
    
    @IBAction func notificationSwitchChanged(_ sender: Any) {
        
        guard let userID = AuthenticationManager.shared.user?.uid else {
            return
        }
        let application = UIApplication.shared
        
        if notificationSwitch.isOn {
            
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("Error fetching FCM registration token: \(error)")
                } else if let token = token {
                    HandyHelper.shared.saveFCMToken(token: token)
                    application.registerForRemoteNotifications()
                    self.alert(message: "You can now receive notifications from Imagine.")
                }
            }
            
        } else {
            
            let userRef = db.collection("Users").document(userID)
            
            userRef.updateData([
                "fcmToken": FieldValue.delete(),
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err.localizedDescription)")
                } else {
                    self.defaults.set(false, forKey: "allowNotifications")
                    application.unregisterForRemoteNotifications()
                    self.alert(message: "You won't receive any notifications from Imagine anymore.")
                }
            }
        }
    }
    
    @IBAction func deleteAccountTapped(_ sender: Any) {
        deleteAccountButton.isEnabled = false
        deleteAccountButton.alpha = 0.5
        
        guard let userID = AuthenticationManager.shared.user?.uid else {
            return
        }
        
        let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
        let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
        let notificationData: [String: Any] = ["type": "message", "message": "Jemand möchte seinen Account löschen", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "UserID": userID]
        
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
    
    @IBAction func languageSegmentedControlChanged(_ sender: Any) {
        let language: String = languageSegmentedControl.selectedSegmentIndex == 0 ? "de" : "en"
        
        defaults.set(language, forKey: "languageSelection")
    }
    
    @IBAction func dataControlTapped(_ sender: Any) {
        let language = LanguageSelection.language
        if language == .de {
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
        let language = LanguageSelection.language
        if language == .de {
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
