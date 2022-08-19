//
//  AppDelegate.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import IQKeyboardManagerSwift
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    

    // Only portrait mode
    var myOrientation = UIInterfaceOrientationMask.portrait
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        myOrientation
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Init Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        // Set FirebaseCloudMessaging for Apple Notification Center
        UNUserNotificationCenter.current().delegate = self
        
        // To have the textViews and textFields always above the keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // Change Color of navigationItem and Barbutton
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.imagineColor, NSAttributedString.Key.font : UIFont(name: "IBMPlexSans", size: 18) ?? UIFont.systemFont(ofSize: 18)], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.imagineColor
        
        // Initiate rootviewcontroller here because otherwise the app would crash because a child of TabBarViewController would call Firebase before FirebaseApp.configure would be called here in AppDelegate
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "initialTabBarVC")
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        do { // If i want to play full screen: https://stackoverflow.com/questions/31828654/turn-off-audio-playback-of-avplayer
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [AVAudioSession.CategoryOptions.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Cant get to the AVAudioSettings: \(error.localizedDescription)")
        }
        
        deleteApplicationBadgeNumber(application: application)
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        deleteApplicationBadgeNumber(application: application)
    }
    
    func deleteApplicationBadgeNumber(application: UIApplication) {
        if application.applicationIconBadgeNumber != 0 {
            application.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - Push Notifications
extension AppDelegate: MessagingDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func registerForPushNoticications(application: UIApplication) {
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            UserDefaults.standard.set(granted, forKey: "allowNotifications")
        }
        
        application.registerForRemoteNotifications()
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error, failed to register to remote Notifications: ", error.localizedDescription)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Called on every App start and whenever a new token is generated
        
        guard let fcmToken = fcmToken else {
            print("Couldnt retrieve fcmToken")
            return
        }
        
        if let currentToken = UserDefaults.standard.value(forKey: "fcmToken") as? String {
            if currentToken != fcmToken {
                //save Token in Database
                HandyHelper.shared.saveFCMToken(token: fcmToken)
            }
        } else {    // No token set in userdefaults yet
            HandyHelper.shared.saveFCMToken(token: fcmToken)
        }
    }
}

